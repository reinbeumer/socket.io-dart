/// room_management_models.dart
///
/// Type-safe models for room management and membership tracking
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library room_management_models;

import '../value_objects/room_name_vo.dart';

/// Represents room membership for a socket.
///
/// Provides type-safe tracking of which rooms a socket belongs to.
class RoomMembership {
  final Map<String, RoomName> _rooms;

  /// Creates an empty room membership.
  RoomMembership() : _rooms = <String, RoomName>{};

  /// Creates from an existing map of room names.
  RoomMembership.fromNames(final Iterable<String> roomNames) : _rooms = <String, RoomName>{} {
    for (final String name in roomNames) {
      final RoomName room = RoomName(name);
      _rooms[room.value] = room;
    }
  }

  /// Creates from RoomName value objects.
  RoomMembership.fromRooms(final Iterable<RoomName> rooms) : _rooms = <String, RoomName>{} {
    for (final RoomName room in rooms) {
      _rooms[room.value] = room;
    }
  }

  /// Adds a room to membership.
  void add(final RoomName room) {
    _rooms[room.value] = room;
  }

  /// Adds a room by name.
  void addByName(final String roomName) {
    final RoomName room = RoomName(roomName);
    _rooms[room.value] = room;
  }

  /// Removes a room from membership.
  bool remove(final RoomName room) => _rooms.remove(room.value) != null;

  /// Removes a room by name.
  bool removeByName(final String roomName) => _rooms.remove(roomName) != null;

  /// Checks if a room is in membership.
  bool contains(final RoomName room) => _rooms.containsKey(room.value);

  /// Checks if a room name is in membership.
  bool containsName(final String roomName) => _rooms.containsKey(roomName);

  /// Gets a room by name, or null if not found.
  RoomName? get(final String roomName) => _rooms[roomName];

  /// Returns all rooms.
  Iterable<RoomName> get rooms => _rooms.values;

  /// Returns all room names.
  Iterable<String> get roomNames => _rooms.keys;

  /// Returns the number of rooms.
  int get length => _rooms.length;

  /// Checks if empty.
  bool get isEmpty => _rooms.isEmpty;

  /// Checks if not empty.
  bool get isNotEmpty => _rooms.isNotEmpty;

  /// Clears all rooms.
  void clear() => _rooms.clear();

  /// Converts to a list of room names.
  List<String> toList() => _rooms.keys.toList();

  /// Converts to a set of room names.
  Set<String> toSet() => _rooms.keys.toSet();

  /// Creates a copy.
  RoomMembership copy() => RoomMembership.fromRooms(_rooms.values);

  @override
  String toString() => 'RoomMembership(${_rooms.keys.join(', ')})';
}

/// Represents a collection of sockets in a room.
///
/// Tracks which sockets are members of a specific room.
class RoomSocketCollection {
  final RoomName roomName;
  final Set<String> _socketIds;

  /// Creates a new room socket collection.
  RoomSocketCollection(this.roomName) : _socketIds = <String>{};

  /// Creates from an existing set of socket IDs.
  RoomSocketCollection.fromIds(this.roomName, final Iterable<String> socketIds)
      : _socketIds = Set<String>.from(socketIds);

  /// Adds a socket to the room.
  bool add(final String socketId) => _socketIds.add(socketId);

  /// Removes a socket from the room.
  bool remove(final String socketId) => _socketIds.remove(socketId);

  /// Checks if a socket is in the room.
  bool contains(final String socketId) => _socketIds.contains(socketId);

  /// Returns all socket IDs in the room.
  Set<String> get socketIds => Set<String>.from(_socketIds);

  /// Returns the number of sockets in the room.
  int get length => _socketIds.length;

  /// Checks if empty.
  bool get isEmpty => _socketIds.isEmpty;

  /// Checks if not empty.
  bool get isNotEmpty => _socketIds.isNotEmpty;

  /// Clears all sockets from the room.
  void clear() => _socketIds.clear();

  /// Creates a copy.
  RoomSocketCollection copy() => RoomSocketCollection.fromIds(roomName, _socketIds);

  @override
  String toString() => 'RoomSocketCollection($roomName: ${_socketIds.length} sockets)';
}

/// Manages room memberships and socket-to-room mappings.
///
/// Provides efficient bidirectional lookup between sockets and rooms.
class RoomManager {
  // Socket ID -> RoomMembership
  final Map<String, RoomMembership> _socketRooms;

  // Room name -> Set of socket IDs
  final Map<String, Set<String>> _roomSockets;

  /// Creates a new room manager.
  RoomManager()
      : _socketRooms = <String, RoomMembership>{},
        _roomSockets = <String, Set<String>>{};

  /// Adds a socket to a room.
  void join(final String socketId, final RoomName room) {
    // Add to socket's room list
    _socketRooms
        .putIfAbsent(
          socketId,
          RoomMembership.new,
        )
        .add(room);

    // Add to room's socket list
    _roomSockets
        .putIfAbsent(
          room.value,
          () => <String>{},
        )
        .add(socketId);
  }

  /// Adds a socket to a room by name.
  void joinByName(final String socketId, final String roomName) {
    join(socketId, RoomName(roomName));
  }

  /// Removes a socket from a room.
  void leave(final String socketId, final RoomName room) {
    // Remove from socket's room list
    final RoomMembership? membership = _socketRooms[socketId];
    if (membership != null) {
      membership.remove(room);
      if (membership.isEmpty) {
        _socketRooms.remove(socketId);
      }
    }

    // Remove from room's socket list
    final Set<String>? sockets = _roomSockets[room.value];
    if (sockets != null) {
      sockets.remove(socketId);
      if (sockets.isEmpty) {
        _roomSockets.remove(room.value);
      }
    }
  }

  /// Removes a socket from a room by name.
  void leaveByName(final String socketId, final String roomName) {
    leave(socketId, RoomName(roomName));
  }

  /// Removes a socket from all rooms.
  void leaveAll(final String socketId) {
    final RoomMembership? membership = _socketRooms.remove(socketId);
    if (membership != null) {
      for (final RoomName room in membership.rooms) {
        final Set<String>? sockets = _roomSockets[room.value];
        if (sockets != null) {
          sockets.remove(socketId);
          if (sockets.isEmpty) {
            _roomSockets.remove(room.value);
          }
        }
      }
    }
  }

  /// Gets all rooms for a socket.
  RoomMembership? getRoomsForSocket(final String socketId) => _socketRooms[socketId]?.copy();

  /// Gets all sockets in a room.
  Set<String> getSocketsInRoom(final RoomName room) {
    final Set<String>? sockets = _roomSockets[room.value];
    return sockets != null ? Set<String>.from(sockets) : <String>{};
  }

  /// Gets all sockets in a room by name.
  Set<String> getSocketsInRoomByName(final String roomName) => getSocketsInRoom(RoomName(roomName));

  /// Checks if a socket is in a room.
  bool isInRoom(final String socketId, final RoomName room) {
    final RoomMembership? membership = _socketRooms[socketId];
    return membership?.contains(room) ?? false;
  }

  /// Checks if a socket is in a room by name.
  bool isInRoomByName(final String socketId, final String roomName) => isInRoom(socketId, RoomName(roomName));

  /// Gets all room names.
  Iterable<String> get allRoomNames => _roomSockets.keys;

  /// Gets all rooms.
  Iterable<RoomName> get allRooms => _roomSockets.keys.map(RoomName.new);

  /// Gets the number of rooms.
  int get roomCount => _roomSockets.length;

  /// Gets the number of sockets being tracked.
  int get socketCount => _socketRooms.length;

  /// Clears all room data.
  void clear() {
    _socketRooms.clear();
    _roomSockets.clear();
  }

  @override
  String toString() => 'RoomManager($roomCount rooms, $socketCount sockets)';
}
