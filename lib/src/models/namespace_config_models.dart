// namespace_config_models.dart
//
// Purpose: Type-safe models for namespace configuration
//
// Description: Provides models for configuring Socket.IO namespaces
// including adapter settings, middleware, and namespace options.

import '../adapter.dart';
import '../value_objects/namespace_name_vo.dart';
import 'callbacks_models.dart';

/// Configuration model for a Socket.IO namespace.
///
/// Provides type-safe configuration options for namespace creation
/// and management.
class NamespaceConfig {
  /// The name of the namespace (must start with '/').
  final NamespaceName name;

  /// Custom adapter factory for the namespace.
  /// If null, uses the server's default adapter.
  final Adapter Function()? adapterFactory;

  /// List of middleware functions to apply to connections.
  final List<MiddlewareCallback> middleware;

  /// Whether to automatically create this namespace on first connection.
  final bool autoCreate;

  /// Maximum number of sockets allowed in this namespace.
  /// Null means unlimited.
  final int? maxSockets;

  /// Creates a namespace configuration.
  ///
  /// [name] - The namespace name (must start with '/')
  /// [adapterFactory] - Optional custom adapter factory
  /// [middleware] - List of middleware functions (default: empty)
  /// [autoCreate] - Whether to auto-create namespace (default: true)
  /// [maxSockets] - Maximum sockets allowed (default: unlimited)
  const NamespaceConfig({
    required this.name,
    this.adapterFactory,
    this.middleware = const <MiddlewareCallback>[],
    this.autoCreate = true,
    this.maxSockets,
  });

  /// Creates a namespace configuration from a plain name string.
  ///
  /// Validates the namespace name format.
  factory NamespaceConfig.fromString(
    final String name, {
    final Adapter Function()? adapterFactory,
    final List<MiddlewareCallback> middleware = const <MiddlewareCallback>[],
    final bool autoCreate = true,
    final int? maxSockets,
  }) =>
      NamespaceConfig(
        name: NamespaceName(name),
        adapterFactory: adapterFactory,
        middleware: middleware,
        autoCreate: autoCreate,
        maxSockets: maxSockets,
      );

  /// Creates a copy with updated values.
  NamespaceConfig copyWith({
    final NamespaceName? name,
    final Adapter Function()? adapterFactory,
    final List<MiddlewareCallback>? middleware,
    final bool? autoCreate,
    final int? maxSockets,
  }) =>
      NamespaceConfig(
        name: name ?? this.name,
        adapterFactory: adapterFactory ?? this.adapterFactory,
        middleware: middleware ?? this.middleware,
        autoCreate: autoCreate ?? this.autoCreate,
        maxSockets: maxSockets ?? this.maxSockets,
      );

  /// Adds middleware to the configuration.
  NamespaceConfig withMiddleware(final MiddlewareCallback middleware) => copyWith(
        middleware: <MiddlewareCallback>[...this.middleware, middleware],
      );

  /// Adds multiple middleware functions.
  NamespaceConfig withMiddlewares(final List<MiddlewareCallback> middlewares) => copyWith(
        middleware: <MiddlewareCallback>[...middleware, ...middlewares],
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is NamespaceConfig &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          autoCreate == other.autoCreate &&
          maxSockets == other.maxSockets;

  @override
  int get hashCode => Object.hash(name, autoCreate, maxSockets);

  @override
  String toString() => 'NamespaceConfig('
      'name: $name, '
      'adapterFactory: ${adapterFactory != null ? 'custom' : 'default'}, '
      'middleware: ${middleware.length} functions, '
      'autoCreate: $autoCreate, '
      'maxSockets: ${maxSockets ?? 'unlimited'}'
      ')';
}

/// Builder for creating namespace configurations.
///
/// Provides a fluent API for building namespace configurations.
class NamespaceConfigBuilder {
  NamespaceName? _name;
  Adapter Function()? _adapterFactory;
  final List<MiddlewareCallback> _middleware = <MiddlewareCallback>[];
  bool _autoCreate = true;
  int? _maxSockets;

  /// Sets the namespace name.
  NamespaceConfigBuilder name(final String name) {
    _name = NamespaceName(name);
    return this;
  }

  /// Sets the namespace name as value object.
  NamespaceConfigBuilder nameVo(final NamespaceName name) {
    _name = name;
    return this;
  }

  /// Sets a custom adapter factory.
  NamespaceConfigBuilder adapterFactory(final Adapter Function() factory) {
    _adapterFactory = factory;
    return this;
  }

  /// Adds a middleware function.
  NamespaceConfigBuilder middleware(final MiddlewareCallback middleware) {
    _middleware.add(middleware);
    return this;
  }

  /// Adds multiple middleware functions.
  NamespaceConfigBuilder middlewares(final List<MiddlewareCallback> middlewares) {
    _middleware.addAll(middlewares);
    return this;
  }

  /// Sets whether to auto-create the namespace.
  NamespaceConfigBuilder autoCreate(final bool autoCreate) {
    _autoCreate = autoCreate;
    return this;
  }

  /// Sets the maximum number of sockets.
  NamespaceConfigBuilder maxSockets(final int maxSockets) {
    if (maxSockets <= 0) {
      throw ArgumentError('maxSockets must be positive');
    }
    _maxSockets = maxSockets;
    return this;
  }

  /// Sets unlimited sockets.
  NamespaceConfigBuilder unlimitedSockets() {
    _maxSockets = null;
    return this;
  }

  /// Builds the namespace configuration.
  ///
  /// Throws [StateError] if required fields are missing.
  NamespaceConfig build() {
    if (_name == null) {
      throw StateError('Namespace name is required');
    }

    return NamespaceConfig(
      name: _name!,
      adapterFactory: _adapterFactory,
      middleware: List<MiddlewareCallback>.unmodifiable(_middleware),
      autoCreate: _autoCreate,
      maxSockets: _maxSockets,
    );
  }
}
