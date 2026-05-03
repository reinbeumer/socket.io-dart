/// transport_models.dart
///
/// Typed configuration models for Socket.IO transport layer to replace dynamic types
/// and provide proper configuration management for WebSocket, polling, and other transports.
library transport_models;

import 'package:meta/meta.dart';

/// Configuration model for transport-specific options.
/// Centralizes transport configuration in a typed structure.
@immutable
class TransportConfigurationModel {
  /// The transport name (e.g., 'websocket', 'polling').
  final String name;

  /// Whether the transport is enabled.
  final bool enabled;

  /// Transport priority (lower numbers = higher priority).
  final int priority;

  /// Connection timeout in milliseconds.
  final int connectionTimeout;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Retry delay in milliseconds.
  final int retryDelay;

  /// Whether to use binary encoding.
  final bool binaryEncoding;

  /// Transport-specific options.
  final Map<String, Object?> options;

  /// Creates a new transport configuration model.
  const TransportConfigurationModel({
    required this.name,
    this.enabled = true,
    this.priority = 0,
    this.connectionTimeout = 20000,
    this.maxRetries = 3,
    this.retryDelay = 1000,
    this.binaryEncoding = false,
    this.options = const <String, Object?>{},
  });

  /// Creates a transport configuration from a legacy map.
  factory TransportConfigurationModel.fromMap(final Map<String, dynamic> map, final String name) =>
      TransportConfigurationModel(
        name: name,
        enabled: map['enabled'] as bool? ?? true,
        priority: map['priority'] as int? ?? 0,
        connectionTimeout: map['connectionTimeout'] as int? ?? 20000,
        maxRetries: map['maxRetries'] as int? ?? 3,
        retryDelay: map['retryDelay'] as int? ?? 1000,
        binaryEncoding: map['binaryEncoding'] as bool? ?? false,
        options: Map<String, Object?>.from((map['options'] as Map<dynamic, dynamic>?) ?? <String, Object?>{}),
      );

  /// Creates a WebSocket transport configuration.
  factory TransportConfigurationModel.websocket({
    final bool enabled = true,
    final int priority = 1,
    final int connectionTimeout = 20000,
    final bool binaryEncoding = true,
    final Map<String, Object?> options = const <String, Object?>{},
  }) =>
      TransportConfigurationModel(
        name: 'websocket',
        enabled: enabled,
        priority: priority,
        connectionTimeout: connectionTimeout,
        binaryEncoding: binaryEncoding,
        options: options,
      );

  /// Creates a polling transport configuration.
  factory TransportConfigurationModel.polling({
    final bool enabled = true,
    final int priority = 2,
    final int connectionTimeout = 30000,
    final bool binaryEncoding = false,
    final Map<String, Object?> options = const <String, Object?>{},
  }) =>
      TransportConfigurationModel(
        name: 'polling',
        enabled: enabled,
        priority: priority,
        connectionTimeout: connectionTimeout,
        binaryEncoding: binaryEncoding,
        options: options,
      );

  /// Gets an option value by key.
  T? getOption<T>(final String key) => options[key] as T?;

  /// Checks if an option exists.
  bool hasOption(final String key) => options.containsKey(key);

  /// Adds or updates an option.
  TransportConfigurationModel setOption(final String key, final Object? value) {
    final Map<String, Object?> newOptions = Map<String, Object?>.from(options);
    newOptions[key] = value;
    return copyWith(options: newOptions);
  }

  /// Removes an option.
  TransportConfigurationModel removeOption(final String key) {
    final Map<String, Object?> newOptions = Map<String, Object?>.from(options)..remove(key);
    return copyWith(options: newOptions);
  }

  /// Converts to a map for backward compatibility.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'enabled': enabled,
        'priority': priority,
        'connectionTimeout': connectionTimeout,
        'maxRetries': maxRetries,
        'retryDelay': retryDelay,
        'binaryEncoding': binaryEncoding,
        'options': options,
      };

  /// Creates a copy with optional parameter overrides.
  TransportConfigurationModel copyWith({
    final String? name,
    final bool? enabled,
    final int? priority,
    final int? connectionTimeout,
    final int? maxRetries,
    final int? retryDelay,
    final bool? binaryEncoding,
    final Map<String, Object?>? options,
  }) =>
      TransportConfigurationModel(
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        priority: priority ?? this.priority,
        connectionTimeout: connectionTimeout ?? this.connectionTimeout,
        maxRetries: maxRetries ?? this.maxRetries,
        retryDelay: retryDelay ?? this.retryDelay,
        binaryEncoding: binaryEncoding ?? this.binaryEncoding,
        options: options ?? this.options,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is TransportConfigurationModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          enabled == other.enabled &&
          priority == other.priority &&
          connectionTimeout == other.connectionTimeout &&
          maxRetries == other.maxRetries &&
          retryDelay == other.retryDelay &&
          binaryEncoding == other.binaryEncoding &&
          _mapsEqual(options, other.options);

  @override
  int get hashCode =>
      name.hashCode ^
      enabled.hashCode ^
      priority.hashCode ^
      connectionTimeout.hashCode ^
      maxRetries.hashCode ^
      retryDelay.hashCode ^
      binaryEncoding.hashCode ^
      options.hashCode;

  @override
  String toString() => 'TransportConfigurationModel('
      'name: $name, '
      'enabled: $enabled, '
      'priority: $priority, '
      'connectionTimeout: $connectionTimeout, '
      'maxRetries: $maxRetries, '
      'retryDelay: $retryDelay, '
      'binaryEncoding: $binaryEncoding, '
      'optionsCount: ${options.length})';

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model specific to WebSocket transport.
@immutable
class WebSocketConfigurationModel extends TransportConfigurationModel {
  /// Whether to enable per-message deflate compression.
  final bool perMessageDeflate;

  /// Maximum window bits for compression.
  final int maxWindowBits;

  /// Compression threshold in bytes.
  final int compressionThreshold;

  /// WebSocket subprotocol.
  final String? subprotocol;

  /// Custom headers for WebSocket handshake.
  final Map<String, String> headers;

  /// Creates a new WebSocket configuration model.
  const WebSocketConfigurationModel({
    super.enabled = true,
    super.priority = 1,
    super.connectionTimeout = 20000,
    super.maxRetries = 3,
    super.retryDelay = 1000,
    super.options = const <String, Object?>{},
    this.perMessageDeflate = true,
    this.maxWindowBits = 15,
    this.compressionThreshold = 1024,
    this.subprotocol,
    this.headers = const <String, String>{},
  }) : super(
          name: 'websocket',
          binaryEncoding: true,
        );

  /// Creates a WebSocket configuration from a legacy map.
  factory WebSocketConfigurationModel.fromMap(final Map<String, dynamic> map) => WebSocketConfigurationModel(
        enabled: map['enabled'] as bool? ?? true,
        priority: map['priority'] as int? ?? 1,
        connectionTimeout: map['connectionTimeout'] as int? ?? 20000,
        maxRetries: map['maxRetries'] as int? ?? 3,
        retryDelay: map['retryDelay'] as int? ?? 1000,
        options: Map<String, Object?>.from((map['options'] as Map<dynamic, dynamic>?) ?? <String, Object?>{}),
        perMessageDeflate: map['perMessageDeflate'] as bool? ?? true,
        maxWindowBits: map['maxWindowBits'] as int? ?? 15,
        compressionThreshold: map['compressionThreshold'] as int? ?? 1024,
        subprotocol: map['subprotocol'] as String?,
        headers: Map<String, String>.from((map['headers'] as Map<dynamic, dynamic>?) ?? <String, String>{}),
      );

  /// Gets a header value by name.
  String? getHeader(final String name) => headers[name];

  /// Adds or updates a header.
  WebSocketConfigurationModel setHeader(final String name, final String value) {
    final Map<String, String> newHeaders = Map<String, String>.from(headers);
    newHeaders[name] = value;
    return copyWith(headers: newHeaders);
  }

  /// Removes a header.
  WebSocketConfigurationModel removeHeader(final String name) {
    final Map<String, String> newHeaders = Map<String, String>.from(headers)..remove(name);
    return copyWith(headers: newHeaders);
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = super.toMap()
      ..addAll(<String, dynamic>{
        'perMessageDeflate': perMessageDeflate,
        'maxWindowBits': maxWindowBits,
        'compressionThreshold': compressionThreshold,
        'headers': headers,
      });
    if (subprotocol != null) map['subprotocol'] = subprotocol;
    return map;
  }

  /// Creates a copy with optional parameter overrides.
  @override
  WebSocketConfigurationModel copyWith({
    final String? name,
    final bool? enabled,
    final int? priority,
    final int? connectionTimeout,
    final int? maxRetries,
    final int? retryDelay,
    final bool? binaryEncoding,
    final Map<String, Object?>? options,
    final bool? perMessageDeflate,
    final int? maxWindowBits,
    final int? compressionThreshold,
    final String? subprotocol,
    final Map<String, String>? headers,
  }) =>
      WebSocketConfigurationModel(
        enabled: enabled ?? this.enabled,
        priority: priority ?? this.priority,
        connectionTimeout: connectionTimeout ?? this.connectionTimeout,
        maxRetries: maxRetries ?? this.maxRetries,
        retryDelay: retryDelay ?? this.retryDelay,
        options: options ?? this.options,
        perMessageDeflate: perMessageDeflate ?? this.perMessageDeflate,
        maxWindowBits: maxWindowBits ?? this.maxWindowBits,
        compressionThreshold: compressionThreshold ?? this.compressionThreshold,
        subprotocol: subprotocol ?? this.subprotocol,
        headers: headers ?? this.headers,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is WebSocketConfigurationModel &&
          super == other &&
          perMessageDeflate == other.perMessageDeflate &&
          maxWindowBits == other.maxWindowBits &&
          compressionThreshold == other.compressionThreshold &&
          subprotocol == other.subprotocol &&
          _mapsEqual(headers, other.headers);

  @override
  int get hashCode =>
      super.hashCode ^
      perMessageDeflate.hashCode ^
      maxWindowBits.hashCode ^
      compressionThreshold.hashCode ^
      subprotocol.hashCode ^
      headers.hashCode;

  @override
  String toString() => 'WebSocketConfigurationModel('
      'enabled: $enabled, '
      'priority: $priority, '
      'perMessageDeflate: $perMessageDeflate, '
      'maxWindowBits: $maxWindowBits, '
      'compressionThreshold: $compressionThreshold, '
      'subprotocol: $subprotocol, '
      'headersCount: ${headers.length})';

  /// Helper method to compare maps for equality.
  @override
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model specific to polling transport.
@immutable
class PollingConfigurationModel extends TransportConfigurationModel {
  /// Polling interval in milliseconds.
  final int pollingInterval;

  /// Maximum number of HTTP requests in flight.
  final int maxHttpRequests;

  /// Whether to use JSONP for cross-domain requests.
  final bool useJsonp;

  /// JSONP callback parameter name.
  final String jsonpCallback;

  /// HTTP method for polling requests.
  final String httpMethod;

  /// Additional HTTP headers.
  final Map<String, String> httpHeaders;

  /// Creates a new polling configuration model.
  const PollingConfigurationModel({
    super.enabled = true,
    super.priority = 2,
    super.connectionTimeout = 30000,
    super.maxRetries = 3,
    super.retryDelay = 1000,
    super.options = const <String, Object?>{},
    this.pollingInterval = 100,
    this.maxHttpRequests = 10,
    this.useJsonp = false,
    this.jsonpCallback = 'callback',
    this.httpMethod = 'GET',
    this.httpHeaders = const <String, String>{},
  }) : super(
          name: 'polling',
          binaryEncoding: false,
        );

  /// Creates a polling configuration from a legacy map.
  factory PollingConfigurationModel.fromMap(final Map<String, dynamic> map) => PollingConfigurationModel(
        enabled: map['enabled'] as bool? ?? true,
        priority: map['priority'] as int? ?? 2,
        connectionTimeout: map['connectionTimeout'] as int? ?? 30000,
        maxRetries: map['maxRetries'] as int? ?? 3,
        retryDelay: map['retryDelay'] as int? ?? 1000,
        options: Map<String, Object?>.from((map['options'] as Map<dynamic, dynamic>?) ?? <String, Object?>{}),
        pollingInterval: map['pollingInterval'] as int? ?? 100,
        maxHttpRequests: map['maxHttpRequests'] as int? ?? 10,
        useJsonp: map['useJsonp'] as bool? ?? false,
        jsonpCallback: map['jsonpCallback'] as String? ?? 'callback',
        httpMethod: map['httpMethod'] as String? ?? 'GET',
        httpHeaders: Map<String, String>.from((map['httpHeaders'] as Map<dynamic, dynamic>?) ?? <String, String>{}),
      );

  /// Gets an HTTP header value by name.
  String? getHttpHeader(final String name) => httpHeaders[name];

  /// Adds or updates an HTTP header.
  PollingConfigurationModel setHttpHeader(final String name, final String value) {
    final Map<String, String> newHeaders = Map<String, String>.from(httpHeaders);
    newHeaders[name] = value;
    return copyWith(httpHeaders: newHeaders);
  }

  /// Removes an HTTP header.
  PollingConfigurationModel removeHttpHeader(final String name) {
    final Map<String, String> newHeaders = Map<String, String>.from(httpHeaders)..remove(name);
    return copyWith(httpHeaders: newHeaders);
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = super.toMap()
      ..addAll(<String, dynamic>{
        'pollingInterval': pollingInterval,
        'maxHttpRequests': maxHttpRequests,
        'useJsonp': useJsonp,
        'jsonpCallback': jsonpCallback,
        'httpMethod': httpMethod,
        'httpHeaders': httpHeaders,
      });
    return map;
  }

  /// Creates a copy with optional parameter overrides.
  @override
  PollingConfigurationModel copyWith({
    final String? name,
    final bool? enabled,
    final int? priority,
    final int? connectionTimeout,
    final int? maxRetries,
    final int? retryDelay,
    final bool? binaryEncoding,
    final Map<String, Object?>? options,
    final int? pollingInterval,
    final int? maxHttpRequests,
    final bool? useJsonp,
    final String? jsonpCallback,
    final String? httpMethod,
    final Map<String, String>? httpHeaders,
  }) =>
      PollingConfigurationModel(
        enabled: enabled ?? this.enabled,
        priority: priority ?? this.priority,
        connectionTimeout: connectionTimeout ?? this.connectionTimeout,
        maxRetries: maxRetries ?? this.maxRetries,
        retryDelay: retryDelay ?? this.retryDelay,
        options: options ?? this.options,
        pollingInterval: pollingInterval ?? this.pollingInterval,
        maxHttpRequests: maxHttpRequests ?? this.maxHttpRequests,
        useJsonp: useJsonp ?? this.useJsonp,
        jsonpCallback: jsonpCallback ?? this.jsonpCallback,
        httpMethod: httpMethod ?? this.httpMethod,
        httpHeaders: httpHeaders ?? this.httpHeaders,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is PollingConfigurationModel &&
          super == other &&
          pollingInterval == other.pollingInterval &&
          maxHttpRequests == other.maxHttpRequests &&
          useJsonp == other.useJsonp &&
          jsonpCallback == other.jsonpCallback &&
          httpMethod == other.httpMethod &&
          _mapsEqual(httpHeaders, other.httpHeaders);

  @override
  int get hashCode =>
      super.hashCode ^
      pollingInterval.hashCode ^
      maxHttpRequests.hashCode ^
      useJsonp.hashCode ^
      jsonpCallback.hashCode ^
      httpMethod.hashCode ^
      httpHeaders.hashCode;

  @override
  String toString() => 'PollingConfigurationModel('
      'enabled: $enabled, '
      'priority: $priority, '
      'pollingInterval: $pollingInterval, '
      'maxHttpRequests: $maxHttpRequests, '
      'useJsonp: $useJsonp, '
      'httpMethod: $httpMethod, '
      'headersCount: ${httpHeaders.length})';

  /// Helper method to compare maps for equality.
  @override
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Model for transport state management.
/// Tracks the current state and history of transport connections.
@immutable
class TransportStateModel {
  /// The current transport state.
  final TransportState state;

  /// Timestamp when the current state was entered.
  final DateTime stateTimestamp;

  /// The transport configuration being used.
  final TransportConfigurationModel configuration;

  /// Number of connection attempts.
  final int attempts;

  /// Last error if any.
  final String? lastError;

  /// Connection statistics.
  final TransportStatsModel stats;

  /// Additional state metadata.
  final Map<String, Object?> metadata;

  /// Creates a new transport state model.
  TransportStateModel({
    required this.state,
    required this.stateTimestamp,
    required this.configuration,
    this.attempts = 0,
    this.lastError,
    final TransportStatsModel? stats,
    this.metadata = const <String, Object?>{},
  }) : stats = stats ?? TransportStatsModel();

  /// Creates an initial transport state.
  factory TransportStateModel.initial(final TransportConfigurationModel configuration) => TransportStateModel(
        state: TransportState.disconnected,
        stateTimestamp: DateTime.now(),
        configuration: configuration,
      );

  /// Creates a connecting state.
  TransportStateModel connecting() => copyWith(
        state: TransportState.connecting,
        stateTimestamp: DateTime.now(),
        attempts: attempts + 1,
      );

  /// Creates a connected state.
  TransportStateModel connected() => copyWith(
        state: TransportState.connected,
        stateTimestamp: DateTime.now(),
        lastError: null,
        stats: stats.incrementConnections(),
      );

  /// Creates a disconnected state.
  TransportStateModel disconnected([final String? error]) => copyWith(
        state: TransportState.disconnected,
        stateTimestamp: DateTime.now(),
        lastError: error,
        stats: stats.incrementDisconnections(),
      );

  /// Creates an error state.
  TransportStateModel error(final String errorMessage) => copyWith(
        state: TransportState.error,
        stateTimestamp: DateTime.now(),
        lastError: errorMessage,
        stats: stats.incrementErrors(),
      );

  /// Gets the duration in the current state.
  Duration get stateAge => DateTime.now().difference(stateTimestamp);

  /// Checks if the transport is connected.
  bool get isConnected => state == TransportState.connected;

  /// Checks if the transport is connecting.
  bool get isConnecting => state == TransportState.connecting;

  /// Checks if the transport is disconnected.
  bool get isDisconnected => state == TransportState.disconnected;

  /// Checks if the transport has an error.
  bool get hasError => state == TransportState.error;

  /// Checks if max retry attempts have been reached.
  bool get maxAttemptsReached => attempts >= configuration.maxRetries;

  /// Adds metadata to the state.
  TransportStateModel addMetadata(final String key, final Object? value) {
    final Map<String, Object?> newMetadata = Map<String, Object?>.from(metadata);
    newMetadata[key] = value;
    return copyWith(metadata: newMetadata);
  }

  /// Gets metadata value by key.
  T? getMetadata<T>(final String key) => metadata[key] as T?;

  /// Converts to a map for serialization.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'state': state.name,
        'stateTimestamp': stateTimestamp.toIso8601String(),
        'configuration': configuration.toMap(),
        'attempts': attempts,
        'lastError': lastError,
        'stats': stats.toMap(),
        'metadata': metadata,
      };

  /// Creates a copy with optional parameter overrides.
  TransportStateModel copyWith({
    final TransportState? state,
    final DateTime? stateTimestamp,
    final TransportConfigurationModel? configuration,
    final int? attempts,
    final String? lastError,
    final TransportStatsModel? stats,
    final Map<String, Object?>? metadata,
  }) =>
      TransportStateModel(
        state: state ?? this.state,
        stateTimestamp: stateTimestamp ?? this.stateTimestamp,
        configuration: configuration ?? this.configuration,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
        stats: stats ?? this.stats,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is TransportStateModel &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          stateTimestamp == other.stateTimestamp &&
          configuration == other.configuration &&
          attempts == other.attempts &&
          lastError == other.lastError &&
          stats == other.stats &&
          _mapsEqual(metadata, other.metadata);

  @override
  int get hashCode =>
      state.hashCode ^
      stateTimestamp.hashCode ^
      configuration.hashCode ^
      attempts.hashCode ^
      lastError.hashCode ^
      stats.hashCode ^
      metadata.hashCode;

  @override
  String toString() => 'TransportStateModel('
      'state: $state, '
      'transport: ${configuration.name}, '
      'attempts: $attempts, '
      'stateAge: ${stateAge.inMilliseconds}ms, '
      'hasError: $hasError)';

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Enumeration of transport states.
enum TransportState {
  /// Transport is disconnected.
  disconnected,

  /// Transport is attempting to connect.
  connecting,

  /// Transport is connected and ready.
  connected,

  /// Transport encountered an error.
  error,
}

/// Model for transport connection statistics.
@immutable
class TransportStatsModel {
  /// Total number of connection attempts.
  final int connectionAttempts;

  /// Number of successful connections.
  final int successfulConnections;

  /// Number of disconnections.
  final int disconnections;

  /// Number of errors encountered.
  final int errors;

  /// Total bytes sent.
  final int bytesSent;

  /// Total bytes received.
  final int bytesReceived;

  /// Number of packets sent.
  final int packetsSent;

  /// Number of packets received.
  final int packetsReceived;

  /// Statistics start time.
  final DateTime startTime;

  /// Creates a new transport statistics model.
  TransportStatsModel({
    this.connectionAttempts = 0,
    this.successfulConnections = 0,
    this.disconnections = 0,
    this.errors = 0,
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.packetsSent = 0,
    this.packetsReceived = 0,
    final DateTime? startTime,
  }) : startTime = startTime ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates initial statistics.
  factory TransportStatsModel.initial() => TransportStatsModel(startTime: DateTime.now());

  /// Increments connection attempts.
  TransportStatsModel incrementAttempts() => copyWith(connectionAttempts: connectionAttempts + 1);

  /// Increments successful connections.
  TransportStatsModel incrementConnections() => copyWith(
        connectionAttempts: connectionAttempts + 1,
        successfulConnections: successfulConnections + 1,
      );

  /// Increments disconnections.
  TransportStatsModel incrementDisconnections() => copyWith(disconnections: disconnections + 1);

  /// Increments errors.
  TransportStatsModel incrementErrors() => copyWith(errors: errors + 1);

  /// Records data sent.
  TransportStatsModel recordDataSent(final int bytes, final int packets) => copyWith(
        bytesSent: bytesSent + bytes,
        packetsSent: packetsSent + packets,
      );

  /// Records data received.
  TransportStatsModel recordDataReceived(final int bytes, final int packets) => copyWith(
        bytesReceived: bytesReceived + bytes,
        packetsReceived: packetsReceived + packets,
      );

  /// Gets the connection success rate.
  double get successRate {
    if (connectionAttempts == 0) return 0.0;
    return successfulConnections / connectionAttempts;
  }

  /// Gets the uptime duration.
  Duration get uptime => DateTime.now().difference(startTime);

  /// Converts to a map for serialization.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'connectionAttempts': connectionAttempts,
        'successfulConnections': successfulConnections,
        'disconnections': disconnections,
        'errors': errors,
        'bytesSent': bytesSent,
        'bytesReceived': bytesReceived,
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'startTime': startTime.toIso8601String(),
        'successRate': successRate,
        'uptime': uptime.inMilliseconds,
      };

  /// Creates a copy with optional parameter overrides.
  TransportStatsModel copyWith({
    final int? connectionAttempts,
    final int? successfulConnections,
    final int? disconnections,
    final int? errors,
    final int? bytesSent,
    final int? bytesReceived,
    final int? packetsSent,
    final int? packetsReceived,
    final DateTime? startTime,
  }) =>
      TransportStatsModel(
        connectionAttempts: connectionAttempts ?? this.connectionAttempts,
        successfulConnections: successfulConnections ?? this.successfulConnections,
        disconnections: disconnections ?? this.disconnections,
        errors: errors ?? this.errors,
        bytesSent: bytesSent ?? this.bytesSent,
        bytesReceived: bytesReceived ?? this.bytesReceived,
        packetsSent: packetsSent ?? this.packetsSent,
        packetsReceived: packetsReceived ?? this.packetsReceived,
        startTime: startTime ?? this.startTime,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is TransportStatsModel &&
          runtimeType == other.runtimeType &&
          connectionAttempts == other.connectionAttempts &&
          successfulConnections == other.successfulConnections &&
          disconnections == other.disconnections &&
          errors == other.errors &&
          bytesSent == other.bytesSent &&
          bytesReceived == other.bytesReceived &&
          packetsSent == other.packetsSent &&
          packetsReceived == other.packetsReceived &&
          startTime == other.startTime;

  @override
  int get hashCode =>
      connectionAttempts.hashCode ^
      successfulConnections.hashCode ^
      disconnections.hashCode ^
      errors.hashCode ^
      bytesSent.hashCode ^
      bytesReceived.hashCode ^
      packetsSent.hashCode ^
      packetsReceived.hashCode ^
      startTime.hashCode;

  @override
  String toString() => 'TransportStatsModel('
      'attempts: $connectionAttempts, '
      'connections: $successfulConnections, '
      'disconnections: $disconnections, '
      'errors: $errors, '
      'sent: ${bytesSent}b/${packetsSent}p, '
      'received: ${bytesReceived}b/${packetsReceived}p, '
      'successRate: ${(successRate * 100).toStringAsFixed(1)}%, '
      'uptime: ${uptime.inSeconds}s)';
}
