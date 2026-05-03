/// error_models.dart
///
/// Enhanced error models for Socket.IO to replace callback-style error handling
/// with proper typed exceptions and error states for better error management.
library error_models;

import 'package:meta/meta.dart';

/// Base sealed class for all Socket.IO errors.
///
/// Using sealed class ensures exhaustive pattern matching and makes the set
/// of error types closed - all subtypes are defined in this file.
/// Provides a common interface for error handling throughout the system.
@immutable
sealed class SocketIOError implements Exception {
  /// The error type identifier.
  String get type;

  /// Human-readable error message.
  String get message;

  /// Optional detailed description.
  String? get description;

  /// Error code for programmatic handling.
  int? get code;

  /// Additional error context data.
  Map<String, Object?> get context;

  /// Timestamp when the error occurred.
  DateTime get timestamp;

  /// Converts the error to a map for serialization.
  Map<String, dynamic> toMap();

  @override
  String toString() => '$type: $message${description != null ? ' - $description' : ''}';
}

/// Enhanced transport error model extending the existing TransportError.
@immutable
class TransportErrorModel extends SocketIOError {
  @override
  final String type;

  @override
  final String message;

  @override
  final String? description;

  @override
  final int? code;

  @override
  final Map<String, Object?> context;

  @override
  final DateTime timestamp;

  /// The transport name that encountered the error.
  final String? transport;

  /// Whether this error is recoverable.
  final bool isRecoverable;

  /// Number of retry attempts made.
  final int retryCount;

  /// Creates a new transport error model.
  TransportErrorModel({
    this.type = 'TransportError',
    required this.message,
    this.description,
    this.code,
    this.context = const <String, Object?>{},
    final DateTime? timestamp,
    this.transport,
    this.isRecoverable = true,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates a transport error from the legacy TransportError.
  factory TransportErrorModel.fromLegacy({
    required final String message,
    final String? description,
    final String type = 'TransportError',
    final String? transport,
  }) =>
      TransportErrorModel(
        type: type,
        message: message,
        description: description,
        transport: transport,
        timestamp: DateTime.now(),
      );

  /// Creates a connection timeout error.
  factory TransportErrorModel.connectionTimeout({
    final String? transport,
    final int timeout = 20000,
  }) =>
      TransportErrorModel(
        type: 'ConnectionTimeout',
        message: 'Connection timeout after ${timeout}ms',
        description: 'The transport failed to establish a connection within the specified timeout period',
        code: 1001,
        transport: transport,
        isRecoverable: true,
        timestamp: DateTime.now(),
        context: <String, Object?>{'timeout': timeout},
      );

  /// Creates a connection refused error.
  factory TransportErrorModel.connectionRefused({
    final String? transport,
    final String? host,
    final int? port,
  }) =>
      TransportErrorModel(
        type: 'ConnectionRefused',
        message: 'Connection refused${host != null ? ' to $host${port != null ? ':$port' : ''}' : ''}',
        description: 'The server actively refused the connection attempt',
        code: 1002,
        transport: transport,
        isRecoverable: false,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (host != null) 'host': host,
          if (port != null) 'port': port,
        },
      );

  /// Creates a protocol error.
  factory TransportErrorModel.protocolError({
    final String? transport,
    required final String reason,
  }) =>
      TransportErrorModel(
        type: 'ProtocolError',
        message: 'Protocol error: $reason',
        description: 'The transport encountered a protocol-level error',
        code: 1003,
        transport: transport,
        isRecoverable: false,
        timestamp: DateTime.now(),
        context: <String, Object?>{'reason': reason},
      );

  /// Creates a transport unavailable error.
  factory TransportErrorModel.transportUnavailable({
    final String? transport,
  }) =>
      TransportErrorModel(
        type: 'TransportUnavailable',
        message: 'Transport $transport is not available',
        description: 'The requested transport is not supported or available in this environment',
        code: 1004,
        transport: transport,
        isRecoverable: false,
        timestamp: DateTime.now(),
      );

  /// Creates a retry error after max attempts.
  TransportErrorModel withRetry() => copyWith(retryCount: retryCount + 1);

  /// Checks if max retries have been reached.
  bool hasExceededMaxRetries(final int maxRetries) => retryCount >= maxRetries;

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'message': message,
        'description': description,
        'code': code,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'transport': transport,
        'isRecoverable': isRecoverable,
        'retryCount': retryCount,
      };

  /// Creates a copy with optional parameter overrides.
  TransportErrorModel copyWith({
    final String? type,
    final String? message,
    final String? description,
    final int? code,
    final Map<String, Object?>? context,
    final DateTime? timestamp,
    final String? transport,
    final bool? isRecoverable,
    final int? retryCount,
  }) =>
      TransportErrorModel(
        type: type ?? this.type,
        message: message ?? this.message,
        description: description ?? this.description,
        code: code ?? this.code,
        context: context ?? this.context,
        timestamp: timestamp ?? this.timestamp,
        transport: transport ?? this.transport,
        isRecoverable: isRecoverable ?? this.isRecoverable,
        retryCount: retryCount ?? this.retryCount,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is TransportErrorModel &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          description == other.description &&
          code == other.code &&
          _mapsEqual(context, other.context) &&
          timestamp == other.timestamp &&
          transport == other.transport &&
          isRecoverable == other.isRecoverable &&
          retryCount == other.retryCount;

  @override
  int get hashCode =>
      type.hashCode ^
      message.hashCode ^
      description.hashCode ^
      code.hashCode ^
      context.hashCode ^
      timestamp.hashCode ^
      transport.hashCode ^
      isRecoverable.hashCode ^
      retryCount.hashCode;

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Error model for connection-related issues.
@immutable
class ConnectionErrorModel extends SocketIOError {
  @override
  final String type;

  @override
  final String message;

  @override
  final String? description;

  @override
  final int? code;

  @override
  final Map<String, Object?> context;

  @override
  final DateTime timestamp;

  /// The connection state when the error occurred.
  final String connectionState;

  /// The namespace where the error occurred.
  final String? namespace;

  /// Creates a new connection error model.

  ConnectionErrorModel({
    this.type = 'ConnectionError',
    required this.message,
    this.description,
    this.code,
    this.context = const <String, Object?>{},
    final DateTime? timestamp,
    required this.connectionState,
    this.namespace,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates an authentication error.
  factory ConnectionErrorModel.authenticationFailed({
    final String? namespace,
    final String? reason,
  }) =>
      ConnectionErrorModel(
        type: 'AuthenticationError',
        message: 'Authentication failed${namespace != null ? ' for namespace $namespace' : ''}',
        description: reason ?? 'Invalid credentials or authentication token',
        code: 2001,
        connectionState: 'authenticating',
        namespace: namespace,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (reason != null) 'reason': reason,
        },
      );

  /// Creates an unauthorized access error.
  factory ConnectionErrorModel.unauthorized({
    final String? namespace,
    final String? resource,
  }) =>
      ConnectionErrorModel(
        type: 'UnauthorizedError',
        message: 'Unauthorized access${namespace != null ? ' to namespace $namespace' : ''}',
        description: 'Insufficient permissions to access the requested resource',
        code: 2002,
        connectionState: 'rejected',
        namespace: namespace,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (resource != null) 'resource': resource,
        },
      );

  /// Creates a namespace not found error.
  factory ConnectionErrorModel.namespaceNotFound({
    required final String namespace,
  }) =>
      ConnectionErrorModel(
        type: 'NamespaceError',
        message: 'Namespace "$namespace" not found',
        description: 'The requested namespace does not exist on the server',
        code: 2003,
        connectionState: 'rejected',
        namespace: namespace,
        timestamp: DateTime.now(),
      );

  /// Creates a connection limit exceeded error.
  factory ConnectionErrorModel.connectionLimitExceeded({
    final String? namespace,
    final int? maxConnections,
  }) =>
      ConnectionErrorModel(
        type: 'ConnectionLimitError',
        message: 'Connection limit exceeded',
        description: 'The server has reached its maximum number of concurrent connections',
        code: 2004,
        connectionState: 'rejected',
        namespace: namespace,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (maxConnections != null) 'maxConnections': maxConnections,
        },
      );

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'message': message,
        'description': description,
        'code': code,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'connectionState': connectionState,
        'namespace': namespace,
      };

  /// Creates a copy with optional parameter overrides.
  ConnectionErrorModel copyWith({
    final String? type,
    final String? message,
    final String? description,
    final int? code,
    final Map<String, Object?>? context,
    final DateTime? timestamp,
    final String? connectionState,
    final String? namespace,
  }) =>
      ConnectionErrorModel(
        type: type ?? this.type,
        message: message ?? this.message,
        description: description ?? this.description,
        code: code ?? this.code,
        context: context ?? this.context,
        timestamp: timestamp ?? this.timestamp,
        connectionState: connectionState ?? this.connectionState,
        namespace: namespace ?? this.namespace,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConnectionErrorModel &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          description == other.description &&
          code == other.code &&
          _mapsEqual(context, other.context) &&
          timestamp == other.timestamp &&
          connectionState == other.connectionState &&
          namespace == other.namespace;

  @override
  int get hashCode =>
      type.hashCode ^
      message.hashCode ^
      description.hashCode ^
      code.hashCode ^
      context.hashCode ^
      timestamp.hashCode ^
      connectionState.hashCode ^
      namespace.hashCode;

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Error model for namespace-related issues.
@immutable
class NamespaceErrorModel extends SocketIOError {
  @override
  final String type;

  @override
  final String message;

  @override
  final String? description;

  @override
  final int? code;

  @override
  final Map<String, Object?> context;

  @override
  final DateTime timestamp;

  /// The namespace where the error occurred.
  final String namespace;

  /// The operation that caused the error.
  final String? operation;

  /// Creates a new namespace error model.
  NamespaceErrorModel({
    this.type = 'NamespaceError',
    required this.message,
    this.description,
    this.code,
    this.context = const <String, Object?>{},
    final DateTime? timestamp,
    required this.namespace,
    this.operation,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates an invalid namespace error.
  factory NamespaceErrorModel.invalidNamespace({
    required final String namespace,
    final String? reason,
  }) =>
      NamespaceErrorModel(
        type: 'InvalidNamespace',
        message: 'Invalid namespace: $namespace',
        description: reason ?? 'The namespace name is not valid',
        code: 3001,
        namespace: namespace,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (reason != null) 'reason': reason,
        },
      );

  /// Creates a namespace operation error.
  factory NamespaceErrorModel.operationFailed({
    required final String namespace,
    required final String operation,
    final String? reason,
  }) =>
      NamespaceErrorModel(
        type: 'NamespaceOperationError',
        message: 'Operation "$operation" failed on namespace "$namespace"',
        description: reason ?? 'The namespace operation could not be completed',
        code: 3002,
        namespace: namespace,
        operation: operation,
        timestamp: DateTime.now(),
        context: <String, Object?>{
          if (reason != null) 'reason': reason,
        },
      );

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'message': message,
        'description': description,
        'code': code,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'namespace': namespace,
        'operation': operation,
      };

  /// Creates a copy with optional parameter overrides.
  NamespaceErrorModel copyWith({
    final String? type,
    final String? message,
    final String? description,
    final int? code,
    final Map<String, Object?>? context,
    final DateTime? timestamp,
    final String? namespace,
    final String? operation,
  }) =>
      NamespaceErrorModel(
        type: type ?? this.type,
        message: message ?? this.message,
        description: description ?? this.description,
        code: code ?? this.code,
        context: context ?? this.context,
        timestamp: timestamp ?? this.timestamp,
        namespace: namespace ?? this.namespace,
        operation: operation ?? this.operation,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NamespaceErrorModel &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          description == other.description &&
          code == other.code &&
          _mapsEqual(context, other.context) &&
          timestamp == other.timestamp &&
          namespace == other.namespace &&
          operation == other.operation;

  @override
  int get hashCode =>
      type.hashCode ^
      message.hashCode ^
      description.hashCode ^
      code.hashCode ^
      context.hashCode ^
      timestamp.hashCode ^
      namespace.hashCode ^
      operation.hashCode;

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Error model for validation issues.
@immutable
class ValidationErrorModel extends SocketIOError {
  @override
  final String type;

  @override
  final String message;

  @override
  final String? description;

  @override
  final int? code;

  @override
  final Map<String, Object?> context;

  @override
  final DateTime timestamp;

  /// The field or parameter that failed validation.
  final String? field;

  /// The expected value or format.
  final String? expected;

  /// The actual value that was provided.
  final Object? actual;

  /// List of validation rules that were violated.
  final List<String> violations;

  /// Creates a new validation error model.
  ValidationErrorModel({
    this.type = 'ValidationError',
    required this.message,
    this.description,
    this.code,
    this.context = const <String, Object?>{},
    final DateTime? timestamp,
    this.field,
    this.expected,
    this.actual,
    this.violations = const <String>[],
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates a required field error.
  factory ValidationErrorModel.requiredField({
    required final String field,
  }) =>
      ValidationErrorModel(
        type: 'RequiredFieldError',
        message: 'Required field "$field" is missing',
        description: 'A required parameter was not provided',
        code: 4001,
        field: field,
        expected: 'non-null value',
        timestamp: DateTime.now(),
        violations: <String>['required'],
      );

  /// Creates an invalid format error.
  factory ValidationErrorModel.invalidFormat({
    required final String field,
    required final String expected,
    final Object? actual,
  }) =>
      ValidationErrorModel(
        type: 'InvalidFormatError',
        message: 'Field "$field" has invalid format',
        description: 'The provided value does not match the expected format',
        code: 4002,
        field: field,
        expected: expected,
        actual: actual,
        timestamp: DateTime.now(),
        violations: <String>['format'],
      );

  /// Creates an out of range error.
  factory ValidationErrorModel.outOfRange({
    required final String field,
    required final Object actual,
    final Object? min,
    final Object? max,
  }) {
    final String range = '${min ?? '∞'} - ${max ?? '∞'}';
    return ValidationErrorModel(
      type: 'OutOfRangeError',
      message: 'Field "$field" is out of range',
      description: 'The provided value is outside the acceptable range',
      code: 4003,
      field: field,
      expected: 'value in range $range',
      actual: actual,
      timestamp: DateTime.now(),
      violations: <String>['range'],
      context: <String, Object?>{
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      },
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'message': message,
        'description': description,
        'code': code,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
        'field': field,
        'expected': expected,
        'actual': actual,
        'violations': violations,
      };

  /// Creates a copy with optional parameter overrides.
  ValidationErrorModel copyWith({
    final String? type,
    final String? message,
    final String? description,
    final int? code,
    final Map<String, Object?>? context,
    final DateTime? timestamp,
    final String? field,
    final String? expected,
    final Object? actual,
    final List<String>? violations,
  }) =>
      ValidationErrorModel(
        type: type ?? this.type,
        message: message ?? this.message,
        description: description ?? this.description,
        code: code ?? this.code,
        context: context ?? this.context,
        timestamp: timestamp ?? this.timestamp,
        field: field ?? this.field,
        expected: expected ?? this.expected,
        actual: actual ?? this.actual,
        violations: violations ?? this.violations,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ValidationErrorModel &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          description == other.description &&
          code == other.code &&
          _mapsEqual(context, other.context) &&
          timestamp == other.timestamp &&
          field == other.field &&
          expected == other.expected &&
          actual == other.actual &&
          _listsEqual(violations, other.violations);

  @override
  int get hashCode =>
      type.hashCode ^
      message.hashCode ^
      description.hashCode ^
      code.hashCode ^
      context.hashCode ^
      timestamp.hashCode ^
      field.hashCode ^
      expected.hashCode ^
      actual.hashCode ^
      violations.hashCode;

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  /// Helper method to compare lists for equality.
  bool _listsEqual(final List<String> a, final List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Factory class for creating common error instances.
class SocketIOErrorFactory {
  /// Creates a generic Socket.IO error.
  static SocketIOError generic({
    required final String message,
    final String? description,
    final int? code,
    final Map<String, Object?> context = const <String, Object?>{},
  }) =>
      _GenericSocketIOError(
        message: message,
        description: description,
        code: code,
        context: context,
      );

  /// Creates an error from an exception.
  static SocketIOError fromException(
    final Exception exception, {
    final String type = 'UnknownError',
    final Map<String, Object?> context = const <String, Object?>{},
  }) =>
      _GenericSocketIOError(
        type: type,
        message: exception.toString(),
        description: 'An unexpected exception occurred',
        code: 9999,
        context: <String, Object?>{
          'originalException': exception.runtimeType.toString(),
          ...context,
        },
      );
}

/// Internal generic error implementation.
@immutable
class _GenericSocketIOError extends SocketIOError {
  @override
  final String type;

  @override
  final String message;

  @override
  final String? description;

  @override
  final int? code;

  @override
  final Map<String, Object?> context;

  @override
  final DateTime timestamp;

  _GenericSocketIOError({
    this.type = 'SocketIOError',
    required this.message,
    this.description,
    this.code,
    this.context = const <String, Object?>{},
    final DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type,
        'message': message,
        'description': description,
        'code': code,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is _GenericSocketIOError &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          message == other.message &&
          description == other.description &&
          code == other.code &&
          _mapsEqual(context, other.context) &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      type.hashCode ^ message.hashCode ^ description.hashCode ^ code.hashCode ^ context.hashCode ^ timestamp.hashCode;

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
