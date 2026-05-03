/// adapter_room_models.dart
///
/// Models for adapter room management to replace dynamic maps
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library adapter_room_models;

/// Represents a socket's membership in various rooms
///
/// This replaces the `Map<String, dynamic>` usage in adapter sids
/// where each socket ID maps to a set of room names.
class SocketRoomMembership {
  /// Set of room names this socket is a member of
  final Set<String> _rooms;

  /// Creates an empty membership
  SocketRoomMembership() : _rooms = <String>{};

  /// Creates membership from existing rooms
  SocketRoomMembership.fromRooms(final Iterable<String> rooms) : _rooms = Set<String>.from(rooms);

  /// Adds a room to this membership
  void addRoom(final String room) {
    _rooms.add(room);
  }

  /// Removes a room from this membership
  bool removeRoom(final String room) => _rooms.remove(room);

  /// Checks if this socket is in a specific room
  bool isInRoom(final String room) => _rooms.contains(room);

  /// Gets all rooms this socket is in
  Set<String> get rooms => Set<String>.unmodifiable(_rooms);

  /// Gets the number of rooms
  int get roomCount => _rooms.length;

  /// Checks if membership is empty
  bool get isEmpty => _rooms.isEmpty;

  /// Checks if membership is not empty
  bool get isNotEmpty => _rooms.isNotEmpty;

  /// Clears all room memberships
  void clear() {
    _rooms.clear();
  }

  /// Creates a copy of this membership
  SocketRoomMembership copy() => SocketRoomMembership.fromRooms(_rooms);

  @override
  String toString() => 'SocketRoomMembership(rooms: $_rooms)';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (other is! SocketRoomMembership) return false;
    if (_rooms.length != other._rooms.length) return false;
    return _rooms.every(other._rooms.contains);
  }

  @override
  int get hashCode => Object.hashAll(_rooms);

  /// Converts to a map for backward compatibility
  ///
  /// Returns a map where each room name maps to `true`
  Map<String, bool> toCompatibilityMap() => Map<String, bool>.fromEntries(
        _rooms.map((final String room) => MapEntry<String, bool>(room, true)),
      );

  /// Creates from a compatibility map
  ///
  /// Accepts the old format: `Map<String, dynamic>` where keys are room names
  factory SocketRoomMembership.fromCompatibilityMap(final Map<String, dynamic> map) =>
      SocketRoomMembership.fromRooms(map.keys);
}

/// Namespace data for adapter
///
/// Replaces dynamic values in adapter.nsps map
class AdapterNamespaceData {
  /// The namespace name
  final String name;

  /// Optional metadata
  final Map<String, Object?> metadata;

  AdapterNamespaceData({
    required this.name,
    final Map<String, Object?>? metadata,
  }) : metadata = metadata ?? <String, Object?>{};

  @override
  String toString() => 'AdapterNamespaceData(name: $name, metadata: $metadata)';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (other is! AdapterNamespaceData) return false;
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}
