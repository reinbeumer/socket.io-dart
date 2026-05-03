/// client_connection_models.dart
///
/// Models for client connection state and management
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library client_connection_models;

import '../value_objects/namespace_name_vo.dart';

/// Represents the state of a client's connection to the server
enum ClientConnectionState {
  /// Client is establishing initial connection
  connecting,

  /// Client is fully connected and authenticated
  connected,

  /// Client is in the process of disconnecting
  disconnecting,

  /// Client is disconnected
  disconnected,

  /// Client connection encountered an error
  error,
}

/// Extension methods for ClientConnectionState
extension ClientConnectionStateExtensions on ClientConnectionState {
  /// Returns true if the client can send/receive data
  bool get isActive => this == ClientConnectionState.connected;

  /// Returns true if the client is in a transitional state
  bool get isTransitioning => this == ClientConnectionState.connecting || this == ClientConnectionState.disconnecting;

  /// Returns true if the client is not connected
  bool get isInactive => this == ClientConnectionState.disconnected || this == ClientConnectionState.error;

  /// Returns a human-readable description of the state
  String get description => switch (this) {
        ClientConnectionState.connecting => 'Establishing connection',
        ClientConnectionState.connected => 'Connected and active',
        ClientConnectionState.disconnecting => 'Disconnecting',
        ClientConnectionState.disconnected => 'Disconnected',
        ClientConnectionState.error => 'Connection error',
      };
}

/// Tracks the namespace connection status for a client
class NamespaceConnectionInfo {
  /// The namespace name
  final NamespaceName namespace;

  /// When the connection was established
  final DateTime connectedAt;

  /// Whether this is the default namespace
  final bool isDefault;

  /// Number of sockets connected to this namespace
  final int socketCount;

  const NamespaceConnectionInfo({
    required this.namespace,
    required this.connectedAt,
    this.isDefault = false,
    this.socketCount = 1,
  });

  /// Creates info for the default namespace
  factory NamespaceConnectionInfo.defaultNamespace({
    required final DateTime connectedAt,
    final int socketCount = 1,
  }) =>
      NamespaceConnectionInfo(
        namespace: NamespaceName.defaultNamespace,
        connectedAt: connectedAt,
        isDefault: true,
        socketCount: socketCount,
      );

  /// Duration since connection was established
  Duration get connectedDuration => DateTime.now().difference(connectedAt);

  /// Creates a copy with updated values
  NamespaceConnectionInfo copyWith({
    final NamespaceName? namespace,
    final DateTime? connectedAt,
    final bool? isDefault,
    final int? socketCount,
  }) =>
      NamespaceConnectionInfo(
        namespace: namespace ?? this.namespace,
        connectedAt: connectedAt ?? this.connectedAt,
        isDefault: isDefault ?? this.isDefault,
        socketCount: socketCount ?? this.socketCount,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NamespaceConnectionInfo &&
          runtimeType == other.runtimeType &&
          namespace == other.namespace &&
          connectedAt == other.connectedAt &&
          isDefault == other.isDefault &&
          socketCount == other.socketCount;

  @override
  int get hashCode => namespace.hashCode ^ connectedAt.hashCode ^ isDefault.hashCode ^ socketCount.hashCode;

  @override
  String toString() =>
      'NamespaceConnectionInfo(namespace: $namespace, connectedAt: $connectedAt, isDefault: $isDefault, socketCount: $socketCount, duration: ${connectedDuration.inSeconds}s)';
}

/// Manages the overall connection state for a client
class ClientConnectionState2 {
  /// Overall connection state
  final ClientConnectionState state;

  /// Map of connected namespaces
  final Map<String, NamespaceConnectionInfo> namespaces;

  /// When the client first connected
  final DateTime? initialConnectionTime;

  /// Last error that occurred, if any
  final String? lastError;

  const ClientConnectionState2({
    required this.state,
    this.namespaces = const <String, NamespaceConnectionInfo>{},
    this.initialConnectionTime,
    this.lastError,
  });

  /// Creates a new connecting state
  factory ClientConnectionState2.connecting() => ClientConnectionState2(
        state: ClientConnectionState.connecting,
        initialConnectionTime: DateTime.now(),
      );

  /// Creates a new connected state
  factory ClientConnectionState2.connected({
    final Map<String, NamespaceConnectionInfo>? namespaces,
  }) =>
      ClientConnectionState2(
        state: ClientConnectionState.connected,
        namespaces: namespaces ?? const <String, NamespaceConnectionInfo>{},
        initialConnectionTime: DateTime.now(),
      );

  /// Creates a new disconnected state
  factory ClientConnectionState2.disconnected({final String? reason}) => ClientConnectionState2(
        state: ClientConnectionState.disconnected,
        lastError: reason,
      );

  /// Creates a new error state
  factory ClientConnectionState2.error(final String error) => ClientConnectionState2(
        state: ClientConnectionState.error,
        lastError: error,
      );

  /// Returns true if connected to any namespace
  bool get hasNamespaces => namespaces.isNotEmpty;

  /// Returns true if connected to default namespace
  bool get hasDefaultNamespace => namespaces.containsKey('/');

  /// Number of connected namespaces
  int get namespaceCount => namespaces.length;

  /// Total duration since initial connection
  Duration? get totalConnectionDuration {
    if (initialConnectionTime == null) return null;
    return DateTime.now().difference(initialConnectionTime!);
  }

  /// Returns true if the client can send/receive data
  bool get isActive => state.isActive && hasNamespaces;

  /// Adds a namespace to the connection state
  ClientConnectionState2 addNamespace(
    final String namespaceName,
    final NamespaceConnectionInfo info,
  ) {
    final Map<String, NamespaceConnectionInfo> updatedNamespaces = Map<String, NamespaceConnectionInfo>.from(namespaces)
      ..[namespaceName] = info;

    return copyWith(
      namespaces: updatedNamespaces,
      state: ClientConnectionState.connected,
    );
  }

  /// Removes a namespace from the connection state
  ClientConnectionState2 removeNamespace(final String namespaceName) {
    final Map<String, NamespaceConnectionInfo> updatedNamespaces = Map<String, NamespaceConnectionInfo>.from(namespaces)
      ..remove(namespaceName);

    return copyWith(namespaces: updatedNamespaces);
  }

  /// Creates a copy with updated values
  ClientConnectionState2 copyWith({
    final ClientConnectionState? state,
    final Map<String, NamespaceConnectionInfo>? namespaces,
    final DateTime? initialConnectionTime,
    final String? lastError,
  }) =>
      ClientConnectionState2(
        state: state ?? this.state,
        namespaces: namespaces ?? this.namespaces,
        initialConnectionTime: initialConnectionTime ?? this.initialConnectionTime,
        lastError: lastError ?? this.lastError,
      );

  @override
  String toString() =>
      'ClientConnectionState(state: ${state.name}, namespaces: ${namespaces.length}, duration: ${totalConnectionDuration?.inSeconds ?? 0}s, error: $lastError)';
}
