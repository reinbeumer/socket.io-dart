/// server_configuration_models.dart
///
/// Typed configuration models for Socket.IO server to replace Map<String, dynamic> usage.
/// These models provide type safety, validation, and better API design.
library server_configuration_models;

import 'package:meta/meta.dart';

/// Configuration model for Socket.IO server options.
/// Replaces the Map<String, dynamic> options parameter in Server constructor.
@immutable
class ServerConfigurationModel {
  /// The path where the Socket.IO client files are served.
  final String path;

  /// Whether to serve the client files.
  final bool serveClient;

  /// The adapter to use for handling connections.
  final String adapter;

  /// The allowed origins for cross-origin requests.
  final String origins;

  /// Additional engine configuration options.
  final EngineConfigurationModel? engineConfig;

  /// Cookie configuration for the server.
  final CookieConfigurationModel? cookieConfig;

  /// Compression configuration for the server.
  final CompressionConfigurationModel? compressionConfig;

  /// Creates a new server configuration model.
  ///
  /// [path] defaults to '/socket.io'
  /// [serveClient] defaults to true
  /// [adapter] defaults to 'default'
  /// [origins] defaults to '*:*'
  const ServerConfigurationModel({
    this.path = '/socket.io',
    this.serveClient = true,
    this.adapter = 'default',
    this.origins = '*:*',
    this.engineConfig,
    this.cookieConfig,
    this.compressionConfig,
  });

  /// Creates a server configuration from a legacy Map<String, dynamic>.
  /// Used for backward compatibility during migration.
  factory ServerConfigurationModel.fromMap(final Map<String, dynamic> map) => ServerConfigurationModel(
        path: map['path'] as String? ?? '/socket.io',
        serveClient: map['serveClient'] as bool? ?? true,
        adapter: map['adapter'] as String? ?? 'default',
        origins: map['origins'] as String? ?? '*:*',
        engineConfig:
            map.containsKey('engine') ? EngineConfigurationModel.fromMap(map['engine'] as Map<String, dynamic>) : null,
        cookieConfig:
            map.containsKey('cookie') ? CookieConfigurationModel.fromMap(map['cookie'] as Map<String, dynamic>) : null,
        compressionConfig: map.containsKey('compression')
            ? CompressionConfigurationModel.fromMap(map['compression'] as Map<String, dynamic>)
            : null,
      );

  /// Converts this configuration to a Map for backward compatibility.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'path': path,
      'serveClient': serveClient,
      'adapter': adapter,
      'origins': origins,
    };

    if (engineConfig != null) {
      map['engine'] = engineConfig!.toMap();
    }
    if (cookieConfig != null) {
      map['cookie'] = cookieConfig!.toMap();
    }
    if (compressionConfig != null) {
      map['compression'] = compressionConfig!.toMap();
    }

    return map;
  }

  /// Creates a copy of this configuration with optional parameter overrides.
  ServerConfigurationModel copyWith({
    final String? path,
    final bool? serveClient,
    final String? adapter,
    final String? origins,
    final EngineConfigurationModel? engineConfig,
    final CookieConfigurationModel? cookieConfig,
    final CompressionConfigurationModel? compressionConfig,
  }) =>
      ServerConfigurationModel(
        path: path ?? this.path,
        serveClient: serveClient ?? this.serveClient,
        adapter: adapter ?? this.adapter,
        origins: origins ?? this.origins,
        engineConfig: engineConfig ?? this.engineConfig,
        cookieConfig: cookieConfig ?? this.cookieConfig,
        compressionConfig: compressionConfig ?? this.compressionConfig,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ServerConfigurationModel &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          serveClient == other.serveClient &&
          adapter == other.adapter &&
          origins == other.origins &&
          engineConfig == other.engineConfig &&
          cookieConfig == other.cookieConfig &&
          compressionConfig == other.compressionConfig;

  @override
  int get hashCode =>
      path.hashCode ^
      serveClient.hashCode ^
      adapter.hashCode ^
      origins.hashCode ^
      engineConfig.hashCode ^
      cookieConfig.hashCode ^
      compressionConfig.hashCode;

  @override
  String toString() => 'ServerConfigurationModel('
      'path: $path, '
      'serveClient: $serveClient, '
      'adapter: $adapter, '
      'origins: $origins, '
      'engineConfig: $engineConfig, '
      'cookieConfig: $cookieConfig, '
      'compressionConfig: $compressionConfig)';
}

/// Configuration model for Engine.IO options.
@immutable
class EngineConfigurationModel {
  /// Ping timeout in milliseconds.
  final int pingTimeout;

  /// Ping interval in milliseconds.
  final int pingInterval;

  /// Maximum HTTP buffer size.
  final int maxHttpBufferSize;

  /// Whether to allow upgrades from polling to websocket.
  final bool allowUpgrades;

  /// The allowed transports.
  final List<String> transports;

  /// Creates a new engine configuration model.
  const EngineConfigurationModel({
    this.pingTimeout = 60000,
    this.pingInterval = 25000,
    this.maxHttpBufferSize = 100000,
    this.allowUpgrades = true,
    this.transports = const <String>['websocket', 'polling'],
  });

  /// Creates an engine configuration from a Map.
  factory EngineConfigurationModel.fromMap(final Map<String, dynamic> map) => EngineConfigurationModel(
        pingTimeout: map['pingTimeout'] as int? ?? 60000,
        pingInterval: map['pingInterval'] as int? ?? 25000,
        maxHttpBufferSize: map['maxHttpBufferSize'] as int? ?? 100000,
        allowUpgrades: map['allowUpgrades'] as bool? ?? true,
        transports: (map['transports'] as List<dynamic>?)?.map((final dynamic e) => e.toString()).toList() ??
            const <String>['websocket', 'polling'],
      );

  /// Converts this configuration to a Map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'pingTimeout': pingTimeout,
        'pingInterval': pingInterval,
        'maxHttpBufferSize': maxHttpBufferSize,
        'allowUpgrades': allowUpgrades,
        'transports': transports,
      };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EngineConfigurationModel &&
          runtimeType == other.runtimeType &&
          pingTimeout == other.pingTimeout &&
          pingInterval == other.pingInterval &&
          maxHttpBufferSize == other.maxHttpBufferSize &&
          allowUpgrades == other.allowUpgrades &&
          transports.toString() == other.transports.toString();

  @override
  int get hashCode =>
      pingTimeout.hashCode ^
      pingInterval.hashCode ^
      maxHttpBufferSize.hashCode ^
      allowUpgrades.hashCode ^
      transports.hashCode;

  @override
  String toString() => 'EngineConfigurationModel('
      'pingTimeout: $pingTimeout, '
      'pingInterval: $pingInterval, '
      'maxHttpBufferSize: $maxHttpBufferSize, '
      'allowUpgrades: $allowUpgrades, '
      'transports: $transports)';
}

/// Configuration model for cookie options.
@immutable
class CookieConfigurationModel {
  /// Cookie name.
  final String name;

  /// Cookie value.
  final String? value;

  /// Cookie domain.
  final String? domain;

  /// Cookie path.
  final String? path;

  /// Whether the cookie is HTTP-only.
  final bool httpOnly;

  /// Whether the cookie requires HTTPS.
  final bool secure;

  /// Cookie same-site policy.
  final String? sameSite;

  /// Creates a new cookie configuration model.
  const CookieConfigurationModel({
    this.name = 'io',
    this.value,
    this.domain,
    this.path,
    this.httpOnly = false,
    this.secure = false,
    this.sameSite,
  });

  /// Creates a cookie configuration from a Map.
  factory CookieConfigurationModel.fromMap(final Map<String, dynamic> map) => CookieConfigurationModel(
        name: map['name'] as String? ?? 'io',
        value: map['value'] as String?,
        domain: map['domain'] as String?,
        path: map['path'] as String?,
        httpOnly: map['httpOnly'] as bool? ?? false,
        secure: map['secure'] as bool? ?? false,
        sameSite: map['sameSite'] as String?,
      );

  /// Converts this configuration to a Map.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'name': name,
      'httpOnly': httpOnly,
      'secure': secure,
    };

    if (value != null) map['value'] = value;
    if (domain != null) map['domain'] = domain;
    if (path != null) map['path'] = path;
    if (sameSite != null) map['sameSite'] = sameSite;

    return map;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is CookieConfigurationModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value &&
          domain == other.domain &&
          path == other.path &&
          httpOnly == other.httpOnly &&
          secure == other.secure &&
          sameSite == other.sameSite;

  @override
  int get hashCode =>
      name.hashCode ^
      value.hashCode ^
      domain.hashCode ^
      path.hashCode ^
      httpOnly.hashCode ^
      secure.hashCode ^
      sameSite.hashCode;

  @override
  String toString() => 'CookieConfigurationModel('
      'name: $name, '
      'value: $value, '
      'domain: $domain, '
      'path: $path, '
      'httpOnly: $httpOnly, '
      'secure: $secure, '
      'sameSite: $sameSite)';
}

/// Configuration model for compression options.
@immutable
class CompressionConfigurationModel {
  /// Whether to enable per-message deflate compression for WebSocket.
  final bool perMessageDeflate;

  /// Whether to enable HTTP compression.
  final bool httpCompression;

  /// Compression threshold in bytes.
  final int threshold;

  /// Creates a new compression configuration model.
  const CompressionConfigurationModel({
    this.perMessageDeflate = true,
    this.httpCompression = true,
    this.threshold = 1024,
  });

  /// Creates a compression configuration from a Map.
  factory CompressionConfigurationModel.fromMap(final Map<String, dynamic> map) => CompressionConfigurationModel(
        perMessageDeflate: map['perMessageDeflate'] as bool? ?? true,
        httpCompression: map['httpCompression'] as bool? ?? true,
        threshold: map['threshold'] as int? ?? 1024,
      );

  /// Converts this configuration to a Map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'perMessageDeflate': perMessageDeflate,
        'httpCompression': httpCompression,
        'threshold': threshold,
      };

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is CompressionConfigurationModel &&
          runtimeType == other.runtimeType &&
          perMessageDeflate == other.perMessageDeflate &&
          httpCompression == other.httpCompression &&
          threshold == other.threshold;

  @override
  int get hashCode => perMessageDeflate.hashCode ^ httpCompression.hashCode ^ threshold.hashCode;

  @override
  String toString() => 'CompressionConfigurationModel('
      'perMessageDeflate: $perMessageDeflate, '
      'httpCompression: $httpCompression, '
      'threshold: $threshold)';
}

/// Legacy settings model to replace the global oldSettings map.
@immutable
class LegacySettingsModel {
  /// Map of old setting names to new setting names.
  static const Map<String, String> settingsMapping = <String, String>{
    'transports': 'transports',
    'heartbeat timeout': 'pingTimeout',
    'heartbeat interval': 'pingInterval',
    'destroy buffer size': 'maxHttpBufferSize',
  };

  /// Gets the modern setting name for a legacy setting.
  static String? getModernSetting(final String legacySetting) => settingsMapping[legacySetting];

  /// Gets all legacy setting names.
  static List<String> get legacySettings => settingsMapping.keys.toList();

  /// Gets all modern setting names.
  static List<String> get modernSettings => settingsMapping.values.toList();
}

/// Origins configuration model for origin validation.
@immutable
class OriginsConfigurationModel {
  /// The allowed origins pattern.
  final String pattern;

  /// Whether to allow all origins.
  final bool allowAll;

  /// List of specific allowed origins.
  final List<String> allowedOrigins;

  /// Creates a new origins configuration model.
  const OriginsConfigurationModel({
    this.pattern = '*:*',
    this.allowAll = true,
    this.allowedOrigins = const <String>[],
  });

  /// Creates an origins configuration from a string pattern.
  factory OriginsConfigurationModel.fromPattern(final String pattern) => OriginsConfigurationModel(
        pattern: pattern,
        allowAll: pattern == '*:*',
        allowedOrigins:
            pattern == '*:*' ? const <String>[] : pattern.split(' ').where((final String s) => s.isNotEmpty).toList(),
      );

  /// Checks if an origin is allowed.
  bool isOriginAllowed(String origin) {
    if (allowAll) return true;
    final String normalizedOrigin = origin.isEmpty ? '*' : origin;

    // Handle file:// URLs
    // Parse origin
    try {
      final Uri uri = Uri.parse(normalizedOrigin);
      final int port = uri.port;
      final String host = uri.host;

      return allowedOrigins.any((final String allowed) {
        if (allowed == '*:*') return true;

        final List<String> parts = allowed.split(':');
        if (parts.length != 2) return false;

        final String allowedHost = parts[0];
        final String allowedPort = parts[1];

        final bool hostMatches = allowedHost == '*' || allowedHost == host;
        final bool portMatches = allowedPort == '*' || allowedPort == port.toString();

        return hostMatches && portMatches;
      });
    } catch (_) {
      return false;
    }
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is OriginsConfigurationModel &&
          runtimeType == other.runtimeType &&
          pattern == other.pattern &&
          allowAll == other.allowAll &&
          allowedOrigins.toString() == other.allowedOrigins.toString();

  @override
  int get hashCode => pattern.hashCode ^ allowAll.hashCode ^ allowedOrigins.hashCode;

  @override
  String toString() => 'OriginsConfigurationModel('
      'pattern: $pattern, '
      'allowAll: $allowAll, '
      'allowedOrigins: $allowedOrigins)';
}
