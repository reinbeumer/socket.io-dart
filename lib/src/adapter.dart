// adapter.dart
//
// Purpose:
//
// Description:
//
// History:
//    16/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';

import 'models/callbacks_models.dart';
import 'namespace.dart';
import 'socket.dart';
import 'util/event_emitter.dart';

/// Room constructor.
///
/// @api private
class _Room {
  Map<String, bool> sockets = <String, bool>{};
  int length = 0;

  /// Adds a socket to a room.
  ///
  /// @param {String} socket id
  /// @api private
  void add(final String id) {
    if (!sockets.containsKey(id)) {
      sockets[id] = true;
      length++;
    }
  }

  /// Removes a socket from a room.
  ///
  /// @param {String} socket id
  /// @api private
  void del(final String id) {
    if (sockets.containsKey(id)) {
      sockets.remove(id);
      length--;
    }
  }
}

abstract class Adapter {
  Map<String, dynamic> nsps = <String, dynamic>{};
  Map<String, _Room> rooms = <String, _Room>{};
  Map<String, Map<String, dynamic>> sids = <String, Map<String, dynamic>>{};

  void add(final String id, final String room, [final ErrorableCallback? fn]);
  void del(final String id, final String room, [final ErrorableCallback? fn]);
  void delAll(final String id, [final ErrorableCallback? fn]);
  void broadcast(final Map<String, dynamic> packet, [final Map<String, dynamic>? opts]);
  void clients([final List<String>? rooms, final ClientsStringCallback? fn]);
  void clientRooms(final String id, [final void Function(Object?, Iterable<dynamic>?)? fn]);

  static Adapter newInstance(final String key, final Namespace nsp) {
    if ('default' == key) {
      return _MemoryStoreAdapter(nsp);
    }
    throw UnimplementedError('not supported other adapter yet.');
  }
}

class _MemoryStoreAdapter extends EventEmitter implements Adapter {
  @override
  Map<String, dynamic> nsps = <String, dynamic>{};
  @override
  Map<String, _Room> rooms = <String, _Room>{};

  @override
  Map<String, Map<String, dynamic>> sids = <String, Map<String, dynamic>>{};
  late dynamic encoder;
  late Namespace nsp;

  _MemoryStoreAdapter(this.nsp) {
    encoder = nsp.server.encoder;
  }

  /// Adds a socket to a room.
  ///
  /// @param {String} socket id
  /// @param {String} room name
  /// @param {Function} callback
  /// @api public

  @override
  void add(final String id, final String room, [final ErrorableCallback? fn]) {
    sids[id] = sids[id] ?? <String, dynamic>{};
    sids[id]![room] = true;
    rooms[room] = rooms[room] ?? _Room();
    rooms[room]!.add(id);
    if (fn != null) scheduleMicrotask(() => fn(null));
  }

  /// Removes a socket from a room.
  ///
  /// @param {String} socket id
  /// @param {String} room name
  /// @param {Function} callback
  /// @api public
  @override
  void del(final String id, final String room, [final ErrorableCallback? fn]) {
    final Map<String, dynamic>? rooms = sids[id];
    if (rooms != null && rooms.containsKey(room)) {
      rooms.remove(room);
      this.rooms[room]?.del(id);
      if (this.rooms[room]?.length == 0) this.rooms.remove(room);
    }
    if (fn != null) scheduleMicrotask(() => fn(null));
  }

  /// Removes a socket from all rooms it's joined.
  ///
  /// @param {String} socket id
  /// @param {Function} callback
  /// @api public
  @override
  void delAll(final String id, [final ErrorableCallback? fn]) {
    final Map<String, dynamic>? rooms = sids[id];
    if (rooms != null) {
      for (final String room in rooms.keys) {
        if (this.rooms.containsKey(room)) {
          this.rooms[room]!.del(id);
          if (this.rooms[room]!.length == 0) this.rooms.remove(room);
        }
      }
    }
    sids.remove(id);

    if (fn != null) scheduleMicrotask(() => fn(null));
  }

  /// Broadcasts a packet.
  ///
  /// Options:
  ///  - `flags` {Object} flags for this packet
  ///  - `except` {Array} sids that should be excluded
  ///  - `rooms` {Array} list of rooms to broadcast to
  ///
  /// @param {Object} packet object
  /// @api public
  @override
  void broadcast(final Map<String, dynamic> packet, [Map<String, dynamic>? opts]) {
    final Map<String, dynamic> options = opts ?? <String, dynamic>{};
    final List<String> rooms = (options['rooms'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final List<String> except = (options['except'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final Map<String, dynamic> flags = (options['flags'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, Object> packetOpts = <String, Object>{
      'preEncoded': true,
      'volatile': flags['volatile'],
      'compress': flags['compress']
    };
    final Set<String> ids = <String>{};

    packet['nsp'] = nsp.name;
    final dynamic encodedPackets = encoder.encode(packet);
    if (rooms.isNotEmpty) {
      for (int i = 0; i < rooms.length; i++) {
        final _Room? room = this.rooms[rooms[i]];
        if (room == null) continue;
        final Map<String, bool> sockets = room.sockets;
        for (final String id in sockets.keys) {
          if (sockets.containsKey(id)) {
            if (ids.contains(id) || except.contains(id)) continue;
            final Socket? socket = nsp.connected[id];
            if (socket != null) {
              socket.packet(encodedPackets, packetOpts);
              ids.add(id);
            }
          }
        }
      }
    } else {
      for (final String id in sids.keys) {
        if (except.contains(id)) continue;
        final Socket? socket = nsp.connected[id];
        if (socket != null) socket.packet(encodedPackets, packetOpts);
      }
    }
  }

  /// Gets a list of clients by sid.
  ///
  /// @param {Array} explicit set of rooms to check.
  /// @param {Function} callback
  /// @api public
  @override
  void clients([final List<String>? rooms, final ClientsStringCallback? fn]) {
    final Set<String> ids = <String>{};
    final List<String> sids = <String>[];

    if (rooms != null && rooms.isNotEmpty) {
      for (int i = 0; i < rooms.length; i++) {
        final _Room? room = this.rooms[rooms[i]];
        if (room == null) continue;
        final Map<String, bool> sockets = room.sockets;
        for (final String id in sockets.keys) {
          if (sockets.containsKey(id)) {
            if (ids.contains(id)) continue;
            final Socket? socket = nsp.connected[id];
            if (socket != null) {
              sids.add(id);
              ids.add(id);
            }
          }
        }
      }
    } else {
      for (final String id in this.sids.keys) {
        final Socket? socket = nsp.connected[id];
        if (socket != null) sids.add(id);
      }
    }

    if (fn != null) scheduleMicrotask(() => fn(sids));
  }

  /// Gets the list of rooms a given client has joined.
  ///
  /// @param {String} socket id
  /// @param {Function} callback
  /// @api public
  @override
  void clientRooms(final String id, [final void Function(Object?, Iterable<dynamic>?)? fn]) {
    final Map<String, dynamic>? rooms = sids[id];
    if (fn != null) scheduleMicrotask(() => fn(null, rooms?.keys));
  }
}
