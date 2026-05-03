// engine.dart
//
// Purpose:
//
// Description:
//
// History:
//    16/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'package:stream/stream.dart';

import '../util/event_emitter.dart';
import 'server.dart';

abstract class Engine extends EventEmitter {
  static Server attach(final StreamServer server, [final Map<String, dynamic>? options]) {
    final Server engine = Server.fromMap(options)..attachTo(server, options);
    return engine;
  }

  dynamic operator [](final Object key) {}

  /// Associates the [key] with the given [value].
  ///
  /// If the key was already in the map, its associated value is changed.
  /// Otherwise the key-value pair is added to the map.
  void operator []=(final String key, final dynamic value) {}
//  init() {}
//  upgrades() {}
//  verify() {}
//  prepare() {}
  void close() {}
//  handleRequest() {}
//  handshake() {}
}
