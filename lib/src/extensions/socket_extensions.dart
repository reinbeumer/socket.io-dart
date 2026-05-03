/// socket_extensions.dart
///
/// Extension methods for Socket operations
///
/// Provides convenient helper methods for common socket operations,
/// room management, and state checks.
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library socket_extensions;

import '../socket.dart';
import '../value_objects/event_name_vo.dart';
import '../value_objects/room_name_vo.dart';
import '../value_objects/socket_state_vo.dart';

/// Extension methods for Socket class
///
/// Provides helper methods for:
/// - Room membership checks
/// - State queries
/// - Event validation
/// - Convenience operations
extension SocketExtensions on Socket {
  /// Check if this socket is a member of the specified room
  ///
  /// Example:
  /// ```dart
  /// if (socket.isInRoom(RoomName('chat-room'))) {
  ///   print('User is in chat room');
  /// }
  /// ```
  bool isInRoom(final RoomName room) => roomMembership.contains(room);

  /// Check if this socket is a member of the specified room (string version)
  ///
  /// Convenience method for backward compatibility
  bool isInRoomString(final String roomName) => roomMembership.containsName(roomName);

  /// Get all rooms this socket is currently a member of
  ///
  /// Returns a list of RoomName value objects
  List<RoomName> getAllRooms() => roomMembership.rooms.toList();

  /// Get all room names as strings
  ///
  /// Convenience method for backward compatibility
  List<String> getAllRoomNames() => roomMembership.roomNames.toList();

  /// Get the number of rooms this socket is a member of
  int get roomCount => roomMembership.length;

  /// Check if socket is not in any rooms
  bool get hasNoRooms => roomMembership.isEmpty;

  /// Check if socket is in one or more rooms
  bool get hasRooms => roomMembership.isNotEmpty;

  /// Get the current state of this socket
  SocketState get state {
    if (connected) {
      return SocketState.connected;
    } else if (disconnected) {
      return SocketState.disconnected;
    } else {
      return SocketState.connecting;
    }
  }

  /// Check if socket is ready to send/receive events
  bool get isReady => connected && !disconnected;

  /// Check if socket is in a transitional state
  bool get isInTransition => !connected && !disconnected;

  /// Check if event name is valid for this socket
  ///
  /// Returns false if the event name is blacklisted or reserved
  bool isEventAllowed(final EventName eventName) => !eventName.isBlacklisted;

  /// Check if event name string is valid for this socket
  ///
  /// Convenience method for string event names
  bool isEventAllowedString(final String eventName) {
    try {
      final EventName event = EventName(eventName);
      return isEventAllowed(event);
    } on ArgumentError {
      return false;
    }
  }

  /// Emit event only if socket is ready
  ///
  /// Returns true if event was emitted, false if socket is not ready
  ///
  /// Example:
  /// ```dart
  /// final bool sent = socket.emitIfReady('message', ['Hello']);
  /// if (!sent) {
  ///   print('Socket not ready, message not sent');
  /// }
  /// ```
  bool emitIfReady(final String event, [final List<Object?>? data]) {
    if (!isReady) {
      return false;
    }
    emit(event, data);
    return true;
  }

  /// Check if this socket has a specific flag set
  ///
  /// Example:
  /// ```dart
  /// if (socket.hasFlag('broadcast')) {
  ///   print('Socket is in broadcast mode');
  /// }
  /// ```
  bool hasFlag(final String flagName) => flags?.containsKey(flagName) == true && flags![flagName] == true;

  /// Get all active flags as a list
  List<String> getActiveFlags() {
    if (flags == null) {
      return <String>[];
    }
    return flags!.entries
        .where((final MapEntry<String, bool> entry) => entry.value == true)
        .map((final MapEntry<String, bool> entry) => entry.key)
        .toList();
  }

  /// Check if socket is in broadcast mode
  bool get isBroadcasting => hasFlag('broadcast');

  /// Check if socket has volatile flag set
  bool get isVolatile => hasFlag('volatile');

  /// Check if socket has compress flag set
  bool get isCompressing => hasFlag('compress');

  /// Get socket connection ID as string
  ///
  /// Convenience method for accessing the connection ID value
  String get connectionIdValue => connectionId.value;

  /// Get namespace name as string
  ///
  /// Convenience method for accessing the namespace name
  String get namespaceName => nsp.name;

  /// Check if socket is connected to the default namespace
  bool get isDefaultNamespace => namespaceName == '/';

  /// Get query parameters as a map
  ///
  /// Returns an empty map if no query parameters are set
  Map<String, String> getQueryMap() => queryParameters?.toMap() ?? <String, String>{};

  /// Get a specific query parameter value
  ///
  /// Returns null if the parameter doesn't exist
  String? getQueryParameter(final String key) => queryParameters?.get(key);

  /// Check if a query parameter exists
  bool hasQueryParameter(final String key) => queryParameters?.has(key) ?? false;
}
