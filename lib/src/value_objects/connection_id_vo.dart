/// connection_id_vo.dart
///
/// Value object for socket connection ID with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library connection_id_vo;

/// Value object representing a validated socket connection ID.
///
/// Connection IDs are automatically generated unique identifiers for each
/// client connection. This value object ensures they are non-empty and
/// provides type safety.
///
/// ## Usage
///
/// ```dart
/// // Created automatically for each socket
/// final socket = ...;
/// print('Connected: ${socket.connectionId}');
///
/// // Manual creation (typically not needed)
/// final id = ConnectionId('abc123');
///
/// // Comparison
/// if (socket1.connectionId == socket2.connectionId) {
///   print('Same connection');
/// }
/// ```
///
/// See also:
/// * [Socket.id] for the string representation
/// * [Socket.connectionId] for the typed value object
class ConnectionId {
  final String value;

  const ConnectionId._(this.value);

  /// Creates a ConnectionId from a string with validation.
  ///
  /// The [id] parameter must be a non-empty string.
  ///
  /// Throws [ArgumentError] if the ID is empty.
  ///
  /// Example:
  /// ```dart
  /// final id = ConnectionId('socket-123');
  /// print(id.value);  // 'socket-123'
  /// ```
  factory ConnectionId(final String id) {
    if (id.isEmpty) {
      throw ArgumentError('Connection ID cannot be empty');
    }
    return ConnectionId._(id);
  }

  /// Creates a ConnectionId without validation.
  ///
  /// Use this constructor only when you're certain the value is valid,
  /// such as when deserializing from a trusted source.
  ///
  /// Example:
  /// ```dart
  /// const id = ConnectionId.unchecked('trusted-id');
  /// ```
  const ConnectionId.unchecked(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is ConnectionId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
