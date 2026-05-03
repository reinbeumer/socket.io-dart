/// event_name_vo.dart
///
/// Value object for event name with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library event_name_vo;

/// Value object representing a validated event name.
///
/// Event names must be non-empty strings and not reserved event names.
class EventName {
  final String value;

  const EventName._(this.value);

  /// Reserved event names that cannot be used for custom events.
  ///
  /// These events are reserved for:
  /// - Connection lifecycle management (connect, connection, disconnect, disconnecting)
  /// - Error handling (error, connect_error)
  /// - Event listener management (newListener, removeListener)
  static const Set<String> reservedNames = <String>{
    'connect',
    'connect_error',
    'connection', // server-side connection event
    'disconnect',
    'disconnecting',
    'newListener',
    'removeListener',
    'error',
  };

  /// Creates an EventName from a string with validation.
  ///
  /// Throws [ArgumentError] if the event name is empty or reserved.
  factory EventName(final String name) {
    if (name.isEmpty) {
      throw ArgumentError('Event name cannot be empty');
    }
    if (reservedNames.contains(name)) {
      throw ArgumentError('Event name "$name" is reserved');
    }
    return EventName._(name);
  }

  /// Creates an EventName without validation (use with caution).
  /// Useful for internal/reserved event names.
  const EventName.unchecked(this.value);

  /// Check if this event name is reserved/blacklisted
  bool get isBlacklisted => reservedNames.contains(value);

  /// Static helper to check if a string event name is reserved
  static bool isReserved(final String eventName) => reservedNames.contains(eventName);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is EventName && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
