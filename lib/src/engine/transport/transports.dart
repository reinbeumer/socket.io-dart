// transports.dart
//
// Purpose:
//
// Description:
//
// History:
//    17/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';

import '../../models/callbacks_models.dart' show VoidCallback;
import '../../models/transport_error_models.dart';
import '../../util/event_emitter.dart';
import '../connect.dart';
import 'jsonp_transport.dart';
import 'websocket_transport.dart';
import 'xhr_transport.dart';

class Transports {
  static List<String> upgradesTo(final String from) {
    if ('polling' == from) {
      return <String>['websocket'];
    }
    return <String>[];
  }

  static Transport newInstance(final String name, final SocketConnect connect) {
    if ('websocket' == name) {
      return WebSocketTransport(connect);
    } else if ('polling' == name) {
      final Map<String, dynamic>? options = connect.dataset['options'] as Map<String, dynamic>?;
      if (options != null && options.containsKey('jsonp') && options['jsonp'] == true) {
        return JSONPTransport(connect);
      } else {
        return XHRTransport(connect);
      }
    }
    throw UnimplementedError('Transport $name is not supported');
  }
}

abstract class Transport extends EventEmitter {
  static final Logger _logger = Logger('socket_io:transport.Transport');
  double? maxHttpBufferSize;
  Map<String, dynamic>? httpCompression;
  Map<String, dynamic>? perMessageDeflate;
  bool? supportsBinary;
  String? sid;
  String? name;
  bool? writable;
  String readyState = 'open';
  bool discarded = false;
  SocketConnect? connect;
  MessageHandler? messageHandler;

  Transport(final SocketConnect connect) {
    final Map<String, dynamic>? options = connect.dataset['options'] as Map<String, dynamic>?;
    if (options != null) {
      messageHandler =
          options.containsKey('messageHandlerFactory') ? options['messageHandlerFactory'](this, connect) : null;
    }
  }

  void discard() {
    discarded = true;
  }

  void onRequest(final SocketConnect connect) {
    this.connect = connect;
  }

  void close([final VoidCallback? closeFn]) {
    if ('closed' == readyState || 'closing' == readyState) return;
    readyState = 'closing';
    doClose(closeFn);
  }

  void doClose([final VoidCallback? callback]);

  void onError(final Object? msg, [final Object? desc]) {
    writable = false;
    if (hasListeners('error')) {
      final TransportError error = TransportError(
        msg: msg?.toString(),
        desc: desc?.toString(),
      );
      // Emit the typed error first
      emit('error', error);
      // And emit a map for backward compatibility with existing listeners
      emit('error', error.toMap());
    } else {
      _logger.fine('ignored transport error $msg ($desc)');
    }
  }

  void onPacket(final Map<String, dynamic> packet) {
    emit('packet', packet);
  }

  void onData(final dynamic data) {
    if (messageHandler != null) {
      messageHandler!.handle(this, data);
    } else {
      onPacket(PacketParser.decodePacket(data, 'utf8')! as Map<String, dynamic>);
    }
  }

  void onClose() {
    readyState = 'closed';
    emit('close');
  }

  void send(final List<Map<String, dynamic>> data);

  bool get supportsFraming;
  bool get handlesUpgrades;
}

abstract class MessageHandler {
  void handle(final Transport transport, /*String|List<int>*/ final dynamic message);
}
