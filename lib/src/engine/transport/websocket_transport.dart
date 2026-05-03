import 'dart:async';

/// websocket_transport.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///    22/02/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';

import '../../models/callbacks_models.dart' show VoidCallback;
import '../connect.dart';
import 'transports.dart';

class WebSocketTransport extends Transport {
  static final Logger _logger = Logger('socket_io:transport.WebSocketTransport');
  @override
  bool get handlesUpgrades => true;
  @override
  bool get supportsFraming => true;
  StreamSubscription<dynamic>? subscription;
  WebSocketTransport(final SocketConnect? connect) : super(connect!) {
    name = 'websocket';
    this.connect = connect;
    subscription = connect.websocket?.listen(onData, onError: onError, onDone: onClose);
    writable = true;
  }

  @override
  void send(final List<Map<String, dynamic>> packets) {
    if (connect != null) super.onRequest(connect!);

    void send(final Object data) {
      _logger.fine('writing "$data"');

      // always creates a new object since ws modifies it
//      var opts = {};
//      if (packet.options != null) {
//        opts['compress'] = packet.options['compress'];
//      }
//
//      if (this.perMessageDeflate != null) {
//        var len = data is String ? UTF8.encode(data).length : data.length;
//        if (len < this.perMessageDeflate['threshold']) {
//          opts['compress'] = false;
//        }
//      }

//      this.writable = false;
      connect!.websocket?.add(data);
    }

//    function onEnd (err) {
//      if (err) return self.onError('write error', err.stack);
//      self.writable = true;
//      self.emit('drain');
//    }
    for (int i = 0; i < packets.length; i++) {
      final Map<String, dynamic> packet = packets[i];
      PacketParser.encodePacket(packet,
          supportsBinary: supportsBinary ?? false, callback: (final dynamic data) => send(data));
    }
  }

  @override
  Future<void> onClose() async {
    super.onClose();

    // workaround for https://github.com/dart-lang/sdk/issues/27414
    if (subscription != null) {
      await subscription!.cancel();
      subscription = null;
    }
  }

  @override
  Future<void> doClose([final VoidCallback? fn]) async {
    await connect!.websocket?.close();
    if (fn != null) fn();
  }
}
