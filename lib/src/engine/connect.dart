// connect.dart
//
// Purpose:
//
// Description:
//
// History:
//    06/03/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';
import 'dart:io';

import 'package:stream/stream.dart';

class SocketConnect extends HttpConnectWrapper {
  WebSocket? _socket;
  Completer<String>? _done;
  bool? _completed;
  SocketConnect(super.origin);

  SocketConnect.fromWebSocket(super.origin, final WebSocket socket) {
    _socket = socket;
  }

  bool isUpgradeRequest() => _socket != null;

  WebSocket? get websocket => _socket;

  Future<String> get done {
    if (_completed == true) {
      return Future<String>.value('done');
    }
    if (_socket != null) {
      return _socket!.done.then((final dynamic _) => 'done');
    } else {
      _done = Completer<String>();
      return _done!.future;
    }
  }

  /// Closes the current connection.
  Future<void> close() async {
    if (_done != null) {
      _done!.complete('done');
    } else if (_socket != null) {
      await _socket!.close();
    } else {
      _completed = true;
    }
  }
}
