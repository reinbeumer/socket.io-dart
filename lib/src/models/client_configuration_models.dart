/// client_configuration_models.dart
///
/// Typed configuration models for Socket.IO client to replace Map<String, String> and
/// other dynamic types with proper model classes for better type safety and API design.
library client_configuration_models;

import 'package:meta/meta.dart';

/// Configuration model for client query parameters.
/// Replaces Map<String, String>? query parameters throughout the codebase.
@immutable
class QueryParametersModel {
  /// The query parameters as a map.
  final Map<String, String> parameters;

  /// Creates a new query parameters model.
  const QueryParametersModel(this.parameters);

  /// Creates an empty query parameters model.
  const QueryParametersModel.empty() : parameters = const <String, String>{};

  /// Creates query parameters from a legacy Map<String, String>.
  factory QueryParametersModel.fromMap(final Map<String, String>? map) =>
      QueryParametersModel(map ?? <String, String>{});

  /// Creates query parameters from a URI query string.
  factory QueryParametersModel.fromQueryString(final String queryString) {
    if (queryString.isEmpty) {
      return const QueryParametersModel.empty();
    }

    final Map<String, String> params = <String, String>{};
    final List<String> pairs = queryString.split('&');

    for (final String pair in pairs) {
      if (pair.isEmpty) continue;

      final List<String> parts = pair.split('=');
      if (parts.length == 2) {
        params[Uri.decodeComponent(parts[0])] = Uri.decodeComponent(parts[1]);
      } else if (parts.length == 1) {
        params[Uri.decodeComponent(parts[0])] = '';
      }
    }

    return QueryParametersModel(params);
  }

  /// Gets a parameter value by key.
  String? operator [](final String key) => parameters[key];

  /// Checks if a parameter exists.
  bool containsKey(final String key) => parameters.containsKey(key);

  /// Gets all parameter keys.
  Iterable<String> get keys => parameters.keys;

  /// Gets all parameter values.
  Iterable<String> get values => parameters.values;

  /// Gets all parameter entries.
  Iterable<MapEntry<String, String>> get entries => parameters.entries;

  /// Checks if the parameters are empty.
  bool get isEmpty => parameters.isEmpty;

  /// Checks if the parameters are not empty.
  bool get isNotEmpty => parameters.isNotEmpty;

  /// Gets the number of parameters.
  int get length => parameters.length;

  /// Converts to a legacy Map<String, String> for backward compatibility.
  Map<String, String> toMap() => Map<String, String>.from(parameters);

  /// Converts to a URI query string.
  String toQueryString() {
    if (parameters.isEmpty) return '';

    final List<String> pairs = <String>[];
    for (final MapEntry<String, String> entry in parameters.entries) {
      final String key = Uri.encodeComponent(entry.key);
      final String value = Uri.encodeComponent(entry.value);
      pairs.add('$key=$value');
    }

    return pairs.join('&');
  }

  /// Creates a copy with additional or updated parameters.
  QueryParametersModel copyWith(final Map<String, String> additionalParams) {
    final Map<String, String> newParams = Map<String, String>.from(parameters)..addAll(additionalParams);
    return QueryParametersModel(newParams);
  }

  /// Creates a copy without specified parameters.
  QueryParametersModel copyWithout(final List<String> keysToRemove) {
    final Map<String, String> newParams = Map<String, String>.from(parameters);
    keysToRemove.forEach(newParams.remove);
    return QueryParametersModel(newParams);
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is QueryParametersModel && runtimeType == other.runtimeType && _mapsEqual(parameters, other.parameters);

  @override
  int get hashCode => parameters.hashCode;

  @override
  String toString() => 'QueryParametersModel(parameters: $parameters)';

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, String> a, final Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, String> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model for client connection buffer management.
/// Replaces List<String> connectBuffer with proper state management.
@immutable
class ConnectionBufferModel {
  /// The list of pending namespace connections.
  final List<String> pendingConnections;

  /// Whether the buffer is enabled.
  final bool enabled;

  /// Maximum buffer size to prevent memory issues.
  final int maxSize;

  /// Creates a new connection buffer model.
  const ConnectionBufferModel({
    this.pendingConnections = const <String>[],
    this.enabled = true,
    this.maxSize = 100,
  });

  /// Creates an empty connection buffer.
  const ConnectionBufferModel.empty() : this();

  /// Creates a connection buffer with initial connections.
  factory ConnectionBufferModel.withConnections(final List<String> connections) =>
      ConnectionBufferModel(pendingConnections: List<String>.from(connections));

  /// Adds a connection to the buffer.
  ConnectionBufferModel add(final String namespace) {
    if (!enabled || pendingConnections.length >= maxSize) {
      return this;
    }

    if (pendingConnections.contains(namespace)) {
      return this; // Already exists
    }

    final List<String> newConnections = List<String>.from(pendingConnections)..add(namespace);
    return copyWith(pendingConnections: newConnections);
  }

  /// Removes a connection from the buffer.
  ConnectionBufferModel remove(final String namespace) {
    final List<String> newConnections = List<String>.from(pendingConnections)..remove(namespace);
    return copyWith(pendingConnections: newConnections);
  }

  /// Clears all pending connections.
  ConnectionBufferModel clear() => copyWith(pendingConnections: const <String>[]);

  /// Checks if a namespace is in the buffer.
  bool contains(final String namespace) => pendingConnections.contains(namespace);

  /// Checks if the buffer is empty.
  bool get isEmpty => pendingConnections.isEmpty;

  /// Checks if the buffer is not empty.
  bool get isNotEmpty => pendingConnections.isNotEmpty;

  /// Gets the number of pending connections.
  int get length => pendingConnections.length;

  /// Checks if the buffer is full.
  bool get isFull => pendingConnections.length >= maxSize;

  /// Gets the pending connections as an iterable.
  Iterable<String> get connections => pendingConnections;

  /// Converts to a legacy List<String> for backward compatibility.
  List<String> toList() => List<String>.from(pendingConnections);

  /// Creates a copy with optional parameter overrides.
  ConnectionBufferModel copyWith({
    final List<String>? pendingConnections,
    final bool? enabled,
    final int? maxSize,
  }) =>
      ConnectionBufferModel(
        pendingConnections: pendingConnections ?? this.pendingConnections,
        enabled: enabled ?? this.enabled,
        maxSize: maxSize ?? this.maxSize,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConnectionBufferModel &&
          runtimeType == other.runtimeType &&
          _listsEqual(pendingConnections, other.pendingConnections) &&
          enabled == other.enabled &&
          maxSize == other.maxSize;

  @override
  int get hashCode => pendingConnections.hashCode ^ enabled.hashCode ^ maxSize.hashCode;

  @override
  String toString() => 'ConnectionBufferModel('
      'pendingConnections: $pendingConnections, '
      'enabled: $enabled, '
      'maxSize: $maxSize)';

  /// Helper method to compare lists for equality.
  bool _listsEqual(final List<String> a, final List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Configuration model for namespace connection data.
/// Organizes namespace connection information in a typed structure.
@immutable
class NamespaceConnectionModel {
  /// The namespace name.
  final String namespace;

  /// Query parameters for this namespace connection.
  final QueryParametersModel queryParams;

  /// Whether this connection is active.
  final bool isActive;

  /// Timestamp when the connection was established.
  final DateTime? connectedAt;

  /// Additional metadata for the connection.
  final Map<String, Object?> metadata;

  /// Creates a new namespace connection model.
  const NamespaceConnectionModel({
    required this.namespace,
    this.queryParams = const QueryParametersModel.empty(),
    this.isActive = false,
    this.connectedAt,
    this.metadata = const <String, Object?>{},
  });

  /// Creates a namespace connection from legacy data.
  factory NamespaceConnectionModel.fromLegacyData({
    required final String namespace,
    final Map<String, String>? query,
    final bool isActive = false,
  }) =>
      NamespaceConnectionModel(
        namespace: namespace,
        queryParams: QueryParametersModel.fromMap(query),
        isActive: isActive,
        connectedAt: isActive ? DateTime.now() : null,
      );

  /// Creates an active connection.
  NamespaceConnectionModel connect() => copyWith(
        isActive: true,
        connectedAt: DateTime.now(),
      );

  /// Creates a disconnected connection.
  NamespaceConnectionModel disconnect() => copyWith(
        isActive: false,
        connectedAt: null,
      );

  /// Updates the query parameters.
  NamespaceConnectionModel updateQuery(final QueryParametersModel newQuery) => copyWith(queryParams: newQuery);

  /// Adds metadata to the connection.
  NamespaceConnectionModel addMetadata(final String key, final Object? value) {
    final Map<String, Object?> newMetadata = Map<String, Object?>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Removes metadata from the connection.
  NamespaceConnectionModel removeMetadata(final String key) {
    final Map<String, Object?> newMetadata = Map<String, Object?>.from(metadata)..remove(key);
    return copyWith(metadata: newMetadata);
  }

  /// Gets metadata value by key.
  T? getMetadata<T>(final String key) => metadata[key] as T?;

  /// Checks if the connection has specific metadata.
  bool hasMetadata(final String key) => metadata.containsKey(key);

  /// Gets the connection duration if active.
  Duration? get connectionDuration {
    if (!isActive || connectedAt == null) return null;
    return DateTime.now().difference(connectedAt!);
  }

  /// Converts to a legacy map format for backward compatibility.
  Map<String, dynamic> toLegacyMap() => <String, dynamic>{
        'namespace': namespace,
        'query': queryParams.toMap(),
        'isActive': isActive,
        'connectedAt': connectedAt?.toIso8601String(),
        'metadata': metadata,
      };

  /// Creates a copy with optional parameter overrides.
  NamespaceConnectionModel copyWith({
    final String? namespace,
    final QueryParametersModel? queryParams,
    final bool? isActive,
    final DateTime? connectedAt,
    final Map<String, Object?>? metadata,
  }) =>
      NamespaceConnectionModel(
        namespace: namespace ?? this.namespace,
        queryParams: queryParams ?? this.queryParams,
        isActive: isActive ?? this.isActive,
        connectedAt: connectedAt ?? this.connectedAt,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NamespaceConnectionModel &&
          runtimeType == other.runtimeType &&
          namespace == other.namespace &&
          queryParams == other.queryParams &&
          isActive == other.isActive &&
          connectedAt == other.connectedAt &&
          _mapsEqual(metadata, other.metadata);

  @override
  int get hashCode =>
      namespace.hashCode ^ queryParams.hashCode ^ isActive.hashCode ^ connectedAt.hashCode ^ metadata.hashCode;

  @override
  String toString() => 'NamespaceConnectionModel('
      'namespace: $namespace, '
      'queryParams: $queryParams, '
      'isActive: $isActive, '
      'connectedAt: $connectedAt, '
      'metadata: $metadata)';

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model for client connection options.
/// Centralizes client configuration in a typed structure.
@immutable
class ClientConfigurationModel {
  /// Default query parameters for all connections.
  final QueryParametersModel defaultQuery;

  /// Connection timeout in milliseconds.
  final int connectionTimeout;

  /// Whether to automatically reconnect.
  final bool autoReconnect;

  /// Reconnection delay in milliseconds.
  final int reconnectionDelay;

  /// Maximum number of reconnection attempts.
  final int maxReconnectionAttempts;

  /// Whether to buffer events when disconnected.
  final bool bufferEvents;

  /// Maximum size of the event buffer.
  final int maxBufferSize;

  /// Creates a new client configuration model.
  const ClientConfigurationModel({
    this.defaultQuery = const QueryParametersModel.empty(),
    this.connectionTimeout = 20000,
    this.autoReconnect = true,
    this.reconnectionDelay = 1000,
    this.maxReconnectionAttempts = 5,
    this.bufferEvents = true,
    this.maxBufferSize = 100,
  });

  /// Creates a client configuration from a legacy options map.
  factory ClientConfigurationModel.fromMap(final Map<String, dynamic> map) => ClientConfigurationModel(
        defaultQuery: QueryParametersModel.fromMap(map['query'] as Map<String, String>?),
        connectionTimeout: map['connectionTimeout'] as int? ?? 20000,
        autoReconnect: map['autoReconnect'] as bool? ?? true,
        reconnectionDelay: map['reconnectionDelay'] as int? ?? 1000,
        maxReconnectionAttempts: map['maxReconnectionAttempts'] as int? ?? 5,
        bufferEvents: map['bufferEvents'] as bool? ?? true,
        maxBufferSize: map['maxBufferSize'] as int? ?? 100,
      );

  /// Converts to a map for backward compatibility.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'query': defaultQuery.toMap(),
        'connectionTimeout': connectionTimeout,
        'autoReconnect': autoReconnect,
        'reconnectionDelay': reconnectionDelay,
        'maxReconnectionAttempts': maxReconnectionAttempts,
        'bufferEvents': bufferEvents,
        'maxBufferSize': maxBufferSize,
      };

  /// Creates a copy with optional parameter overrides.
  ClientConfigurationModel copyWith({
    final QueryParametersModel? defaultQuery,
    final int? connectionTimeout,
    final bool? autoReconnect,
    final int? reconnectionDelay,
    final int? maxReconnectionAttempts,
    final bool? bufferEvents,
    final int? maxBufferSize,
  }) =>
      ClientConfigurationModel(
        defaultQuery: defaultQuery ?? this.defaultQuery,
        connectionTimeout: connectionTimeout ?? this.connectionTimeout,
        autoReconnect: autoReconnect ?? this.autoReconnect,
        reconnectionDelay: reconnectionDelay ?? this.reconnectionDelay,
        maxReconnectionAttempts: maxReconnectionAttempts ?? this.maxReconnectionAttempts,
        bufferEvents: bufferEvents ?? this.bufferEvents,
        maxBufferSize: maxBufferSize ?? this.maxBufferSize,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ClientConfigurationModel &&
          runtimeType == other.runtimeType &&
          defaultQuery == other.defaultQuery &&
          connectionTimeout == other.connectionTimeout &&
          autoReconnect == other.autoReconnect &&
          reconnectionDelay == other.reconnectionDelay &&
          maxReconnectionAttempts == other.maxReconnectionAttempts &&
          bufferEvents == other.bufferEvents &&
          maxBufferSize == other.maxBufferSize;

  @override
  int get hashCode =>
      defaultQuery.hashCode ^
      connectionTimeout.hashCode ^
      autoReconnect.hashCode ^
      reconnectionDelay.hashCode ^
      maxReconnectionAttempts.hashCode ^
      bufferEvents.hashCode ^
      maxBufferSize.hashCode;

  @override
  String toString() => 'ClientConfigurationModel('
      'defaultQuery: $defaultQuery, '
      'connectionTimeout: $connectionTimeout, '
      'autoReconnect: $autoReconnect, '
      'reconnectionDelay: $reconnectionDelay, '
      'maxReconnectionAttempts: $maxReconnectionAttempts, '
      'bufferEvents: $bufferEvents, '
      'maxBufferSize: $maxBufferSize)';
}
