/// room_name_vo.dart
///
/// Value object for room name with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library room_name_vo;

/// Value object representing a validated room name.
///
/// Rooms are arbitrary channels that sockets can join and leave. They provide
/// a way to broadcast events to a subset of connected clients. This value object
/// ensures room names are non-empty and provides type safety.
///
/// ## Usage
///
/// ```dart
/// // Join a room
/// final roomName = RoomName('chatRoom');
/// socket.join(roomName.value);
///
/// // Broadcast to room
/// io.to('chatRoom').emit('message', ['Hello room!']);
///
/// // Leave room
/// socket.leave('chatRoom');
///
/// // Check room membership
/// if (socket.roomMembership.contains(RoomName('chatRoom'))) {
///   print('Socket is in chatRoom');
/// }
/// ```
///
/// ## Common Room Patterns
///
/// ```dart
/// // User-specific rooms
/// socket.join(RoomName('user-${userId}'));
///
/// // Broadcast channels
/// socket.join(RoomName('notifications'));
///
/// // Temporary rooms
/// socket.join(RoomName('game-${gameId}'));
/// ```
///
/// See also:
/// * [Socket.join] for joining rooms
/// * [Socket.leave] for leaving rooms
/// * [Namespace.to] for room-based broadcasting
class RoomName {
  final String value;

  const RoomName._(this.value);

  /// Creates a RoomName from a string with validation.
  ///
  /// Throws [ArgumentError] if the room name is empty or invalid.
  factory RoomName(final String name) {
    if (name.isEmpty) {
      throw ArgumentError('Room name cannot be empty');
    }
    return RoomName._(name);
  }

  /// Creates a RoomName without validation (use with caution).
  const RoomName.unchecked(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is RoomName && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
