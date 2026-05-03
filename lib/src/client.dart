// client.dart
//
// Purpose:
//
// Description:
//
// History:
//    22/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:io';

import 'package:logging/logging.dart';

import '../socket_io.dart' show CONNECT, CONNECT_ERROR, Decoder, Encoder;
import 'engine/socket.dart' as engine;
import 'models/connect_buffer_models.dart';
import 'models/packet_models.dart';
import 'models/socket_error_models.dart';
import 'namespace.dart';
import 'server.dart';
import 'socket.dart' as io;
import 'types/common_types.dart';

class Client {
  Server server;
  engine.Socket conn;
  String id;
  HttpRequest request;
  Encoder encoder = Encoder();
  Decoder decoder = Decoder();
  List<io.Socket> sockets = <io.Socket>[];
  Map<String, io.Socket> nsps = <String, io.Socket>{};
  ConnectBuffer connectBuffer = ConnectBuffer();
  final Logger _logger = Logger('socket_io:Client');

  /// Client constructor.
  ///
  /// @param {Server} server instance
  /// @param {Socket} connection
  /// @api private
  Client(this.server, this.conn)
      : id = conn.id,
        request = conn.connect.request {
    setup();
  }

  /// Sets up event listeners.
  ///
  /// @api private
  void setup() {
    decoder.on('decoded', (final dynamic data) => ondecoded(data as JsonMap));
    conn
      ..on('data', (final dynamic data) => ondata(data as Object))
      ..on('error', (final dynamic err) => onerror(err as Object))
      ..on('close', (final dynamic reason) => onclose(reason is String ? reason : reason.toString()));
  }

  /// Connects a client to a namespace.
  ///
  /// @param {String} namespace name
  /// @api private
  void connect(final String name, [final Map<String, String>? query]) {
    _logger.fine('connecting to namespace $name');
    if (!server.nsps.containsKey(name)) {
      packet(<String, dynamic>{'type': CONNECT_ERROR, 'nsp': name, 'data': 'Invalid namespace'});
      return;
    }

    // Socket.IO v3: Check if already connected to this namespace
    // If so, the client is just sending the CONNECT packet (v3 protocol)
    // The client already received the CONNECT acknowledgment, so just ignore this
    if (nsps.containsKey(name)) {
      _logger.fine('already connected to namespace $name, ignoring duplicate CONNECT (client: ${conn.transport.name})');
      return;
    }

    final Namespace nsp = server.of(name);
    if ('/' != name && !nsps.containsKey('/')) {
      connectBuffer.add(name);
      return;
    }

    final Client self = this;
    nsp.add(this, query, (final io.Socket socket) {
      self.sockets.add(socket);
      self.nsps[nsp.name] = socket;

      if ('/' == nsp.name && self.connectBuffer.isNotEmpty) {
        self.connectBuffer.processAll(self.connect);
      }
    });
  }

  /// Disconnects from all namespaces and closes transport.
  ///
  /// @api private
  void disconnect() {
    // we don't use a for loop because the length of
    // `sockets` changes upon each iteration
    sockets.toList().forEach((final io.Socket socket) {
      socket.disconnect();
    });
    sockets.clear();

    close();
  }

  /// Removes a socket. Called by each `Socket`.
  ///
  /// @api private
  void remove(final io.Socket socket) {
    final int i = sockets.indexOf(socket);
    if (i != -1) {
      final String nsp = sockets[i].nsp.name;
      sockets.removeAt(i);
      nsps.remove(nsp);
    } else {
      _logger.fine('ignoring remove for ${socket.id}');
    }
  }

  /// Closes the underlying connection.
  ///
  /// @api private
  void close() {
    if ('open' == conn.readyState) {
      _logger.fine('forcing transport close');
      conn.close();
      onclose('forced server close');
    }
  }

  /// Writes a packet to the transport.
  ///
  /// @param {Object} packet object
  /// @param {Object} options
  /// @api private
  void packet(final Object packet, [final Map<String, Object>? opts]) {
    final Client self = this;
    final Map<String, Object> options = opts ?? <String, Object>{};
    // this writes to the actual connection
    void writeToEngine(final List<Object> encodedPackets) {
      final bool isVolatile = options['volatile'] == true;
      if (isVolatile && self.conn.transport.writable != true) {
        return;
      }
      final bool compress = options['compress'] == true;
      for (int i = 0; i < encodedPackets.length; i++) {
        self.conn.write(encodedPackets[i], <String, bool>{'compress': compress});
      }
    }

    if ('open' == conn.readyState) {
      _logger.fine('writing packet $packet');
      if (options['preEncoded'] != true) {
        // not broadcasting, need to encode
        final List<Object> encodedPackets = List<Object>.from(encoder.encode(packet as Map<String, dynamic>));
        // encode, then write results to engine
        writeToEngine(encodedPackets);
      } else {
        // a broadcast pre-encodes a packet
        writeToEngine(List<Object>.from(packet as List<Object>));
      }
    } else {
      _logger.fine('ignoring packet write $packet');
    }
  }

  /// Writes a typed packet to the transport (type-safe alternative).
  ///
  /// @param {SocketIOPacket} packet - The typed packet to send
  /// @param {Map<String, Object>} opts - Optional transmission options
  /// @api private
  void sendPacket(final SocketIOPacket packet, [final Map<String, Object>? opts]) {
    this.packet(packet.toMap(), opts);
  }

  /// Called with incoming transport data.
  ///
  /// @api private
  void ondata(final Object data) {
    // try/catch is needed for protocol violations (GH-1880)
    try {
      decoder.add(data);
    } on Object catch (e, st) {
      _logger.severe(e, st);
      onerror(e);
    }
  }

  /// Called when parser fully decodes a packet.
  ///
  /// @api private
  void ondecoded(final Map<String, dynamic> packet) {
    _logger.fine('decoded packet: ${packet['type']} for namespace ${packet['nsp']}');
    if (CONNECT == packet['type']) {
      final String nsp = packet['nsp'] as String;
      final Uri uri = Uri.parse(nsp);
      connect(uri.path, uri.queryParameters);
    } else {
      final io.Socket? socket = nsps[packet['nsp']];
      if (socket != null) {
        socket.onpacket(packet);
      } else {
        _logger.fine('no socket for namespace packet.nsp');
      }
    }
  }

  /// Handles an error.
  ///
  /// @param {Object} error object
  /// @api private
  void onerror(final Object err) {
    for (final io.Socket socket in sockets) {
      socket.onerror(err);
    }
    onclose('client error');
  }

  /// Handles an error with type-safe wrapper (preferred).
  ///
  /// @param {SocketErrorModel} error - The typed error model
  /// @api private
  void onErrorTyped(final SocketErrorModel error) {
    onerror(error);
  }

  /// Called upon transport close.
  ///
  /// @param {String} reason
  /// @api private
  void onclose(final String reason) {
    _logger.fine('client close with reason $reason');

    // ignore a potential subsequent `close` event
    destroy();

    // `nsps` and `sockets` are cleaned up seamlessly
    if (sockets.isNotEmpty) {
      for (final io.Socket socket in sockets.toList()) {
        socket.onclose(reason);
      }
      sockets.clear();
    }
    decoder.destroy(); // clean up decoder
  }

  /// Cleans up event listeners.
  ///
  /// @api private
  void destroy() {
    conn
      ..off('data', (final Object? data) => ondata(data as Object))
      ..off('error', (final Object? err) => onerror(err as Object))
      ..off('close', (final Object? reason) => onclose(reason as String));
    decoder.off('decoded', (final Object? data) => ondecoded(data as JsonMap));
  }
}
