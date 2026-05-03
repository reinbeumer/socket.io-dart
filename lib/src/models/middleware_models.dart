/// middleware_models.dart
///
/// Type-safe models for Socket.IO middleware
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library middleware_models;

import '../value_objects/namespace_name_vo.dart';
import 'socket_error_models.dart';

/// Context passed to middleware functions.
///
/// Contains socket information and methods for middleware to inspect
/// and potentially modify the connection process.
class MiddlewareContext {
  /// The socket attempting to connect.
  final dynamic socket;

  /// The namespace being connected to.
  final NamespaceName namespace;

  /// Authentication data provided by the client.
  final Map<String, dynamic>? auth;

  /// Custom data that can be set by middleware.
  final Map<String, Object?> data;

  /// Whether the connection has been rejected.
  bool _rejected = false;

  /// The error that caused rejection, if any.
  SocketErrorModel? _error;

  /// Creates a middleware context.
  MiddlewareContext({
    required this.socket,
    required this.namespace,
    this.auth,
  }) : data = <String, Object?>{};

  /// Checks if the connection has been rejected.
  bool get isRejected => _rejected;

  /// Gets the rejection error, if any.
  SocketErrorModel? get error => _error;

  /// Rejects the connection with an error.
  void reject(final SocketErrorModel error) {
    _rejected = true;
    _error = error;
  }

  /// Rejects the connection with a simple message.
  void rejectWithMessage(final String message) {
    reject(SocketErrorModel.unauthorized(message));
  }

  /// Sets a custom data value.
  void setData(final String key, final Object? value) {
    data[key] = value;
  }

  /// Gets a custom data value.
  Object? getData(final String key) => data[key];

  /// Checks if a data key exists.
  bool hasData(final String key) => data.containsKey(key);
}

/// Result of middleware execution.
class MiddlewareResult {
  /// Whether the middleware chain should continue.
  final bool shouldContinue;

  /// The error that caused the middleware to fail, if any.
  final SocketErrorModel? error;

  const MiddlewareResult._({
    required this.shouldContinue,
    this.error,
  });

  /// Creates a successful result that allows continuation.
  const MiddlewareResult.success() : this._(shouldContinue: true);

  /// Creates a failed result with an error.
  const MiddlewareResult.failure(final SocketErrorModel error) : this._(shouldContinue: false, error: error);

  /// Creates a failed result with a message.
  factory MiddlewareResult.failureWithMessage(final String message) =>
      MiddlewareResult.failure(SocketErrorModel.unauthorized(message));

  /// Whether the middleware succeeded.
  bool get isSuccess => shouldContinue;

  /// Whether the middleware failed.
  bool get isFailure => !shouldContinue;
}

/// A middleware function that can inspect/modify connection attempts.
///
/// Returns a future that resolves to a MiddlewareResult indicating
/// whether the connection should proceed or be rejected.
typedef MiddlewareFunction = Future<MiddlewareResult> Function(
  MiddlewareContext context,
);

/// Synchronous version of middleware function.
typedef SyncMiddlewareFunction = MiddlewareResult Function(
  MiddlewareContext context,
);

/// Manages a chain of middleware functions.
class MiddlewareChain {
  final List<MiddlewareFunction> _middlewares;

  /// Creates an empty middleware chain.
  MiddlewareChain() : _middlewares = <MiddlewareFunction>[];

  /// Creates a middleware chain with initial middlewares.
  MiddlewareChain.withMiddlewares(final List<MiddlewareFunction> middlewares)
      : _middlewares = List<MiddlewareFunction>.from(middlewares);

  /// Adds a middleware to the chain.
  void add(final MiddlewareFunction middleware) {
    _middlewares.add(middleware);
  }

  /// Adds a synchronous middleware to the chain.
  void addSync(final SyncMiddlewareFunction middleware) {
    _middlewares.add((final MiddlewareContext context) async => middleware(context));
  }

  /// Removes a middleware from the chain.
  bool remove(final MiddlewareFunction middleware) => _middlewares.remove(middleware);

  /// Clears all middlewares.
  void clear() => _middlewares.clear();

  /// Gets the number of middlewares.
  int get length => _middlewares.length;

  /// Checks if empty.
  bool get isEmpty => _middlewares.isEmpty;

  /// Checks if not empty.
  bool get isNotEmpty => _middlewares.isNotEmpty;

  /// Executes the middleware chain.
  ///
  /// Runs each middleware in order until one fails or all succeed.
  /// Returns the first failure or success if all pass.
  Future<MiddlewareResult> execute(final MiddlewareContext context) async {
    for (final MiddlewareFunction middleware in _middlewares) {
      final MiddlewareResult result = await middleware(context);
      if (result.isFailure) {
        return result;
      }

      // Check if context was rejected directly
      if (context.isRejected) {
        return MiddlewareResult.failure(
          context.error ?? SocketErrorModel.unauthorized('Connection rejected'),
        );
      }
    }
    return const MiddlewareResult.success();
  }

  @override
  String toString() => 'MiddlewareChain(${_middlewares.length} middlewares)';
}

/// Common middleware functions.
class Middlewares {
  /// Creates a middleware that logs all connection attempts.
  static MiddlewareFunction logging({
    required final void Function(String) log,
  }) =>
      (final MiddlewareContext context) async {
        log('Connection attempt to ${context.namespace}');
        return const MiddlewareResult.success();
      };

  /// Creates a middleware that requires authentication.
  static MiddlewareFunction requireAuth({
    required final Future<bool> Function(Map<String, dynamic>) validate,
  }) =>
      (final MiddlewareContext context) async {
        if (context.auth == null || context.auth!.isEmpty) {
          return MiddlewareResult.failureWithMessage('Authentication required');
        }

        final bool isValid = await validate(context.auth!);
        if (!isValid) {
          return MiddlewareResult.failureWithMessage('Invalid authentication');
        }

        return const MiddlewareResult.success();
      };

  /// Creates a middleware that checks for specific auth tokens.
  static MiddlewareFunction requireToken({
    required final String tokenKey,
    required final bool Function(String) validate,
  }) =>
      (final MiddlewareContext context) async {
        final Object? token = context.auth?[tokenKey];
        if (token == null || token is! String) {
          return MiddlewareResult.failureWithMessage('Token required');
        }

        if (!validate(token)) {
          return MiddlewareResult.failureWithMessage('Invalid token');
        }

        return const MiddlewareResult.success();
      };

  /// Creates a middleware that rate limits connections.
  static MiddlewareFunction rateLimit({
    required final bool Function(dynamic socket) checkLimit,
  }) =>
      (final MiddlewareContext context) async {
        if (!checkLimit(context.socket)) {
          return MiddlewareResult.failureWithMessage('Rate limit exceeded');
        }
        return const MiddlewareResult.success();
      };
}
