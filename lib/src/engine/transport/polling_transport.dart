// polling_transport.dart
//
// Purpose:
//
// Description:
//
// History:
//    22/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';

import '../../models/callbacks_models.dart' show VoidCallback;
import '../../types/common_types.dart' show Headers;
import '../connect.dart';
import 'transports.dart';

class PollingTransport extends Transport {
  @override
  bool get handlesUpgrades => false;

  @override
  bool get supportsFraming => false;

  static final Logger _logger = Logger('socket_io:transport.PollingTransport');
  int closeTimeout = 30 * 1000;
  VoidCallback? shouldClose;
  SocketConnect? dataReq;

  final Map<SocketConnect, VoidCallback> _reqCleanups = <SocketConnect, VoidCallback>{};
  final Map<SocketConnect, VoidCallback> _reqCloses = <SocketConnect, VoidCallback>{};

  PollingTransport(super.connect) {
    maxHttpBufferSize = null;
    httpCompression = null;
    name = 'polling';
  }

  @override
  Future<void> onRequest(final SocketConnect connect) async {
    final HttpResponse res = connect.response;

    if ('GET' == connect.request.method) {
      await onPollRequest(connect);
    } else if ('POST' == connect.request.method) {
      await onDataRequest(connect);
    } else if ('OPTIONS' == connect.request.method) {
      await onOptionsRequest(connect);
    } else {
      res.statusCode = 500;
      await res.close();
    }
  }

  /// Handle CORS preflight requests
  Future<void> onOptionsRequest(final SocketConnect connect) async {
    final HttpResponse res = connect.response;
    final Headers headers = <String, String>{};

    this.headers(connect, headers).forEach((final String key, final Object value) {
      res.headers.set(key, value);
    });

    res
      ..statusCode = 200
      ..write('');
    await res.close();
    await connect.close();
  }

  /// The client sends a request awaiting for us to send data.
  Future<void> onPollRequest(final SocketConnect connect) async {
    if (this.connect != null) {
      _logger.fine('request overlap');
      onError('overlap from client');
      connect.response.statusCode = 500;
      await connect.close();
      return;
    }

    _logger.fine('setting request');
    this.connect = connect;

    void cleanup() {
      this.connect = null;
    }

    void onClose() {
      cleanup();
    }

    _reqCleanups[connect] = cleanup;
    _reqCloses[connect] = onClose;

    writable = true;
    emit('drain', null);

    // if we're still writable but had a pending close, trigger an empty send
    if (writable == true && shouldClose != null) {
      _logger.fine('triggering empty send to append close packet');
      send(<Map<String, dynamic>>[
        <String, String>{'type': 'noop'}
      ]);
    }
  }

  /// The client sends a request with data.
  Future<void> onDataRequest(final SocketConnect connect) async {
    if (dataReq != null) {
      onError('data request overlap from client');
      connect.response.statusCode = 500;
      await connect.close();
      return;
    }

    final bool isBinary = 'application/octet-stream' == connect.request.headers.value('content-type');

    dataReq = connect;
    dynamic chunks = isBinary ? <int>[] : '';
    final PollingTransport self = this;
    int contentLength = 0;

    void cleanup() {
      chunks = isBinary ? <int>[] : '';
      self.dataReq = null;
    }

    Future<void> onData(final Uint8List data) async {
      if (chunks is String) {
        chunks += String.fromCharCodes(data);
        contentLength = utf8.encode(chunks).length;
      } else {
        chunks.addAll(data);
        contentLength = chunks.length;
      }

      if (contentLength > (self.maxHttpBufferSize ?? 1000000)) {
        chunks = '';
        await connect.close();
        return;
      }
    }

    Future<void> onEnd() async {
      self.onData(chunks);
      final Headers headers = <String, Object>{'Content-Type': 'text/html', 'Content-Length': 2};
      final HttpResponse res = connect.response;
      res.headers.clear();

      self.headers(connect, headers).forEach((final String key, final Object value) {
        res.headers.set(key, value);
      });
      res
        ..statusCode = 200
        ..write('ok');
      await connect.close();
      cleanup();
    }

    connect.request.listen(onData, onDone: onEnd);

    if (!isBinary) {
      connect.response.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
    }

    _reqCleanups[connect] = cleanup;
    _reqCloses[connect] = cleanup;
  }

  /// Processes the incoming data payload.
  @override
  void onData(final dynamic data) {
    _logger.fine('received "$data"');
    if (messageHandler != null) {
      messageHandler!.handle(this, data);
    } else {
      if (data is String && data.isNotEmpty) {
        final List<String> packets = _extractPacketStrings(data);

        for (final String packetData in packets) {
          if (packetData.isEmpty) continue;

          try {
            final Map<String, dynamic>? packet = PacketParser.decodePacket(packetData, 'utf8') as Map<String, dynamic>?;
            if (_handleDecodedPacket(packet)) {
              return;
            }
          } catch (e, st) {
            _logger.warning('Error decoding packet "$packetData": $e\n$st');
          }
        }
      } else if (data is List<int>) {
        try {
          final Map<String, dynamic>? packet = PacketParser.decodePacket(data, null) as Map<String, dynamic>?;
          if (_handleDecodedPacket(packet)) {
            return;
          }
        } catch (e, st) {
          _logger.warning('Error decoding binary packet: $e\n$st');
        }
      }
    }
  }

  bool _handleDecodedPacket(final Map<String, dynamic>? packet) {
    if (packet == null) {
      return false;
    }

    if ('close' == packet['type']) {
      _logger.fine('got polling close packet');
      onClose();
      return true;
    }

    onPacket(packet);
    return false;
  }

  /// Extracts individual packets from a text polling payload.
  ///
  /// Engine.IO v4 uses the record-separator character for multi-packet payloads.
  /// Some clients have also been observed to concatenate packets directly,
  /// so we keep the fallback splitter for compatibility.
  List<String> _extractPacketStrings(final String payload) {
    if (payload.contains(SEPARATOR)) {
      return payload.split(SEPARATOR);
    }

    return _splitPackets(payload);
  }

  /// Splits concatenated packets in a fallback polling payload.
  List<String> _splitPackets(final String payload) {
    final List<String> packets = <String>[];
    int start = 0;

    for (int i = 1; i < payload.length; i++) {
      if (_isDigit(payload[i])) {
        final String prevChar = payload[i - 1];
        if (prevChar == ']' || prevChar == '}' || prevChar == '"') {
          packets.add(payload.substring(start, i));
          start = i;
        }
      }
    }

    if (start < payload.length) {
      packets.add(payload.substring(start));
    }

    return packets;
  }

  bool _isDigit(final String char) {
    if (char.isEmpty) return false;
    final int code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  /// Overrides onClose.
  @override
  void onClose() {
    if (writable == true) {
      // close pending poll request
      send(<Map<String, dynamic>>[
        <String, String>{'type': 'noop'}
      ]);
    }
    super.onClose();
  }

  /// Writes a packet payload.
  @override
  void send(final List<Map<String, dynamic>> packets) {
    writable = false;

    if (shouldClose != null) {
      _logger.fine('appending close packet to payload');
      packets.add(<String, String>{'type': 'close'});
      shouldClose!();
      shouldClose = null;
    }

    PacketParser.encodePayload(packets, callback: (final dynamic data) async {
      final bool compress = packets.any((final Map<String, dynamic> packet) {
        final Map<String, bool>? opt = packet['options'] as Map<String, bool>?;
        return opt != null && opt['compress'] == true;
      });
      await write(data, <String, bool>{'compress': compress});
    });
  }

  /// Writes data as response to poll request.
  Future<void> write(final dynamic data, final Map<String, bool> options) async {
    _logger.fine('writing "$data"');
    await doWrite(data, options, () {
      final Function? fn = _reqCleanups.remove(connect);
      if (fn != null) fn();
    });
  }

  /// Performs the write.
  Future<void> doWrite(final dynamic data, final Map<String, bool>? options, [final Function? callback]) async {
    final PollingTransport self = this;

    final bool isString = data is String;
    final String contentType = isString ? 'text/plain; charset=UTF-8' : 'application/octet-stream';

    final Headers headers = <String, Object>{'Content-Type': contentType};

    Future<void> respond(final dynamic data) async {
      headers[HttpHeaders.contentLengthHeader] = data is String ? utf8.encode(data).length : data.length;

      if (self.connect != null) {
        final HttpResponse res = self.connect!.response;

        if (res.statusCode != 101) {
          res.statusCode = 200;
          res.headers.clear();

          self.headers(connect!, headers).forEach((final String k, final Object v) {
            res.headers.set(k, v);
          });

          try {
            if (data is String) {
              res.write(data);
            } else {
              if (headers.containsKey(HttpHeaders.contentEncodingHeader)) {
                res.add(data);
              } else {
                res.write(String.fromCharCodes(data));
              }
            }
            await connect!.close();
          } catch (e) {
            final Function? fn = _reqCloses.remove(connect);
            if (fn != null) fn();
            rethrow;
          }
        }
      }

      if (callback != null) callback();
    }

    if (httpCompression == null || options?['compress'] != true) {
      await respond(data);
      return;
    }

    final int len = isString ? utf8.encode(data).length : data.length;
    if (len < (httpCompression?['threshold'] ?? 1024)) {
      await respond(data);
      return;
    }

    final String? encodings = connect!.request.headers.value(HttpHeaders.acceptEncodingHeader);
    final bool hasGzip = encodings?.contains('gzip') ?? false;
    if (!hasGzip && !(encodings?.contains('deflate') ?? false)) {
      await respond(data);
      return;
    }

    final String encoding = hasGzip ? 'gzip' : 'deflate';
    headers[HttpHeaders.contentEncodingHeader] = encoding;

    if (hasGzip) {
      final String dataString = data is List ? String.fromCharCodes(data as List<int>) : data;
      await respond(gzip.encode(utf8.encode(dataString)));
    } else {
      await respond(data);
    }
  }

  /// Overrides `doClose`.
  @override
  void doClose([final VoidCallback? fn]) {
    _logger.fine('polling transport closing');

    final PollingTransport self = this;
    Timer? closeTimeoutTimer;

    if (dataReq != null) {
      _logger.fine('aborting ongoing data request');
      dataReq = null;
    }

    void onCloseCallback() {
      if (closeTimeoutTimer != null) closeTimeoutTimer.cancel();
      if (fn != null) fn();
      self.onClose();
    }

    if (writable == true) {
      _logger.fine('transport writable - closing right away');
      send(<Map<String, dynamic>>[
        <String, String>{'type': 'close'}
      ]);
      onCloseCallback();
    } else if (discarded == true) {
      _logger.fine('transport discarded - closing right away');
      onCloseCallback();
    } else {
      _logger.fine('transport not writable - buffering orderly close');
      shouldClose = onCloseCallback;
      closeTimeoutTimer = Timer(Duration(milliseconds: closeTimeout), onCloseCallback);
    }
  }

  /// Returns headers for a response.
  Headers headers(final SocketConnect connect, [Headers? headers]) {
    final Headers responseHeaders = headers ?? <String, Object>{};

    // Add CORS headers for cross-origin requests - CRITICAL for fallback
    final String? origin = connect.request.headers.value('origin');
    if (origin != null) {
      responseHeaders['Access-Control-Allow-Origin'] = origin;
      responseHeaders['Access-Control-Allow-Credentials'] = 'true';
    } else {
      responseHeaders['Access-Control-Allow-Origin'] = '*';
    }

    responseHeaders['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
    responseHeaders['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With';
    responseHeaders['Access-Control-Max-Age'] = '86400';

    // prevent XSS warnings on IE
    final String? ua = connect.request.headers.value('user-agent');
    if (ua != null && (ua.contains(';MSIE') || ua.contains('Trident/'))) {
      responseHeaders['X-XSS-Protection'] = '0';
    }

    // Add cache control headers to prevent caching - CRITICAL for real-time
    responseHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    responseHeaders['Pragma'] = 'no-cache';
    responseHeaders['Expires'] = '0';

    emit('headers', responseHeaders);
    return responseHeaders;
  }
}
