/// socket_error_models.dart
///
/// Type-safe models for Socket.IO errors
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library socket_error_models;

/// Enumeration of error types in Socket.IO.
enum SocketErrorType {
  /// Connection error.
  connection,

  /// Transport error.
  transport,

  /// Timeout error.
  timeout,

  /// Authentication error.
  authentication,

  /// Invalid namespace error.
  invalidNamespace,

  /// Parse error.
  parse,

  /// Encoding error.
  encoding,

  /// Decoding error.
  decoding,

  /// Unknown/generic error.
  unknown,
}

/// Model representing a Socket.IO error.
class SocketErrorModel implements Exception {
  /// Type of error.
  final SocketErrorType type;

  /// Error message.
  final String message;

  /// Original error object (if any).
  final Object? originalError;

  /// Stack trace (if available).
  final StackTrace? stackTrace;

  /// Additional error data.
  final Map<String, Object?>? data;

  const SocketErrorModel({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
    this.data,
  });

  /// Creates a connection error.
  factory SocketErrorModel.connection(
    final String message, {
    final Object? originalError,
    final StackTrace? stackTrace,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.connection,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates a transport error.
  factory SocketErrorModel.transport(
    final String message, {
    final Object? originalError,
    final StackTrace? stackTrace,
    final Map<String, Object?>? data,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.transport,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
        data: data,
      );

  /// Creates a timeout error.
  factory SocketErrorModel.timeout(
    final String message, {
    final Duration? duration,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.timeout,
        message: message,
        data: duration != null ? <String, Object?>{'duration': duration.inMilliseconds} : null,
      );

  /// Creates an authentication error.
  factory SocketErrorModel.authentication(final String message) => SocketErrorModel(
        type: SocketErrorType.authentication,
        message: message,
      );

  /// Creates an unauthorized error (alias for authentication).
  factory SocketErrorModel.unauthorized(final String message) => SocketErrorModel(
        type: SocketErrorType.authentication,
        message: message,
      );

  /// Creates an invalid namespace error.
  factory SocketErrorModel.invalidNamespace(final String namespace) => SocketErrorModel(
        type: SocketErrorType.invalidNamespace,
        message: 'Invalid namespace: $namespace',
        data: <String, Object?>{'namespace': namespace},
      );

  /// Creates a parse error.
  factory SocketErrorModel.parse(
    final String message, {
    final Object? originalError,
    final StackTrace? stackTrace,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.parse,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates an encoding error.
  factory SocketErrorModel.encoding(
    final String message, {
    final Object? originalError,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.encoding,
        message: message,
        originalError: originalError,
      );

  /// Creates a decoding error.
  factory SocketErrorModel.decoding(
    final String message, {
    final Object? originalError,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.decoding,
        message: message,
        originalError: originalError,
      );

  /// Creates an unknown/generic error.
  factory SocketErrorModel.unknown(
    final String message, {
    final Object? originalError,
    final StackTrace? stackTrace,
  }) =>
      SocketErrorModel(
        type: SocketErrorType.unknown,
        message: message,
        originalError: originalError,
        stackTrace: stackTrace,
      );

  /// Creates from a generic Object error.
  factory SocketErrorModel.fromObject(final Object error, [final StackTrace? stackTrace]) {
    if (error is SocketErrorModel) return error;
    if (error is Exception) {
      return SocketErrorModel(
        type: SocketErrorType.unknown,
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    return SocketErrorModel(
      type: SocketErrorType.unknown,
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Converts to a Map for serialization.
  Map<String, Object?> toMap() => <String, Object?>{
        'type': type.name,
        'message': message,
        if (data != null) 'data': data,
      };

  /// Converts to a JSON-compatible Map for sending over the wire.
  Map<String, Object?> toJson() => toMap();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SocketErrorModel && runtimeType == other.runtimeType && type == other.type && message == other.message;

  @override
  int get hashCode => Object.hash(type, message);

  @override
  String toString() => 'SocketErrorModel(type: ${type.name}, message: $message)';
}

/// Extension methods for error handling.
extension ErrorConversion on Object {
  /// Converts any object to a SocketErrorModel.
  SocketErrorModel toSocketError([final StackTrace? stackTrace]) => SocketErrorModel.fromObject(this, stackTrace);
}
