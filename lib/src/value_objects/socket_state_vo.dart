/// socket_state_vo.dart
///
/// Value object for socket connection state
///
/// Provides type-safe representation of socket connection lifecycle states
/// to replace string literals like 'connected', 'disconnected', etc.
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library socket_state_vo;

/// Socket connection state
///
/// Represents the lifecycle states of a Socket.IO connection.
/// This enum provides type safety and exhaustive pattern matching
/// for socket state checks.
enum SocketState {
  /// Socket is in the process of establishing a connection
  connecting('connecting'),

  /// Socket is fully connected and ready to send/receive events
  connected('connected'),

  /// Socket is in the process of disconnecting
  disconnecting('disconnecting'),

  /// Socket is disconnected and not active
  disconnected('disconnected');

  /// String value used in protocol and for backward compatibility
  final String value;

  const SocketState(this.value);

  /// Creates a SocketState from a string value
  ///
  /// Returns null if the string doesn't match any known state.
  ///
  /// Example:
  /// ```dart
  /// final SocketState? state = SocketState.fromString('connected');
  /// assert(state == SocketState.connected);
  /// ```
  static SocketState? fromString(final String value) {
    switch (value) {
      case 'connecting':
        return SocketState.connecting;
      case 'connected':
        return SocketState.connected;
      case 'disconnecting':
        return SocketState.disconnecting;
      case 'disconnected':
        return SocketState.disconnected;
      default:
        return null;
    }
  }

  /// Creates a SocketState from a string value with fallback
  ///
  /// Returns the provided [defaultState] if the string doesn't match
  /// any known state.
  ///
  /// Example:
  /// ```dart
  /// final SocketState state = SocketState.fromStringOrDefault(
  ///   'invalid',
  ///   SocketState.disconnected,
  /// );
  /// assert(state == SocketState.disconnected);
  /// ```
  static SocketState fromStringOrDefault(
    final String value,
    final SocketState defaultState,
  ) =>
      fromString(value) ?? defaultState;

  /// Check if socket is in a connected state
  bool get isConnected => this == SocketState.connected;

  /// Check if socket is in a disconnected state
  bool get isDisconnected => this == SocketState.disconnected;

  /// Check if socket is in a transitional state (connecting or disconnecting)
  bool get isTransitioning => this == SocketState.connecting || this == SocketState.disconnecting;

  /// Check if socket can send/receive events
  bool get canCommunicate => this == SocketState.connected;

  @override
  String toString() => value;
}
