// server_options_models.dart
//
// Typed models for Engine.IO server configuration options
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.

import '../value_objects/timeout_duration_vo.dart';
import '../value_objects/transport_name_vo.dart';
import '../value_objects/url_path_vo.dart';

/// Callback type for request verification
typedef AllowRequestCallback = bool Function(dynamic request, dynamic Function(dynamic, bool) callback);

/// Cookie configuration - either a string name or disabled (false)
sealed class CookieConfig {
  const CookieConfig();

  /// Cookie is enabled with the given name
  factory CookieConfig.enabled(final String name) = EnabledCookie;

  /// Cookie is disabled
  factory CookieConfig.disabled() = DisabledCookie;

  /// Check if cookie is enabled
  bool get isEnabled;

  /// Get the cookie name (null if disabled)
  String? get name;

  /// Convert to dynamic for backward compatibility
  dynamic toCompatibility() => switch (this) {
        EnabledCookie() => (this as EnabledCookie).cookieName,
        DisabledCookie() => false,
      };

  /// Create from dynamic value
  factory CookieConfig.fromDynamic(final dynamic value) {
    if (value == false || value == null) {
      return CookieConfig.disabled();
    }
    return CookieConfig.enabled(value.toString());
  }
}

final class EnabledCookie extends CookieConfig {
  final String cookieName;

  const EnabledCookie(this.cookieName);

  @override
  bool get isEnabled => true;

  @override
  String? get name => cookieName;
}

final class DisabledCookie extends CookieConfig {
  const DisabledCookie();

  @override
  bool get isEnabled => false;

  @override
  String? get name => null;
}

/// Cookie path configuration - either a string path or disabled (false)
sealed class CookiePathConfig {
  const CookiePathConfig();

  /// Cookie path is enabled with the given path
  factory CookiePathConfig.enabled(final String path) = EnabledCookiePath;

  /// Cookie path is disabled
  factory CookiePathConfig.disabled() = DisabledCookiePath;

  /// Check if cookie path is enabled
  bool get isEnabled;

  /// Get the cookie path (null if disabled)
  String? get path;

  /// Convert to dynamic for backward compatibility
  dynamic toCompatibility() => switch (this) {
        EnabledCookiePath() => (this as EnabledCookiePath).cookiePath,
        DisabledCookiePath() => false,
      };

  /// Create from dynamic value
  factory CookiePathConfig.fromDynamic(final dynamic value) {
    if (value == false || value == null) {
      return CookiePathConfig.disabled();
    }
    return CookiePathConfig.enabled(value.toString());
  }
}

final class EnabledCookiePath extends CookiePathConfig {
  final String cookiePath;

  const EnabledCookiePath(this.cookiePath);

  @override
  bool get isEnabled => true;

  @override
  String? get path => cookiePath;
}

final class DisabledCookiePath extends CookiePathConfig {
  const DisabledCookiePath();

  @override
  bool get isEnabled => false;

  @override
  String? get path => null;
}

/// Per-message deflate compression configuration
class PerMessageDeflateConfig {
  /// Threshold in bytes below which messages are not compressed
  final int threshold;

  /// Additional configuration options
  final Map<String, Object?> additionalOptions;

  const PerMessageDeflateConfig({
    this.threshold = 1024,
    this.additionalOptions = const <String, Object?>{},
  });

  /// Create from Map for backward compatibility
  factory PerMessageDeflateConfig.fromMap(final Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const PerMessageDeflateConfig();
    }

    final int threshold = map['threshold'] as int? ?? 1024;
    final Map<String, Object?> additional = Map<String, Object?>.from(map)..remove('threshold');

    return PerMessageDeflateConfig(
      threshold: threshold,
      additionalOptions: additional,
    );
  }

  /// Convert to Map for backward compatibility
  Map<String, dynamic> toMap() => <String, dynamic>{
        'threshold': threshold,
        ...additionalOptions,
      };
}

/// HTTP compression configuration
class HttpCompressionConfig {
  /// Threshold in bytes below which responses are not compressed
  final int threshold;

  /// Additional configuration options
  final Map<String, Object?> additionalOptions;

  const HttpCompressionConfig({
    this.threshold = 1024,
    this.additionalOptions = const <String, Object?>{},
  });

  /// Create from Map for backward compatibility
  factory HttpCompressionConfig.fromMap(final Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const HttpCompressionConfig();
    }

    final int threshold = map['threshold'] as int? ?? 1024;
    final Map<String, Object?> additional = Map<String, Object?>.from(map)..remove('threshold');

    return HttpCompressionConfig(
      threshold: threshold,
      additionalOptions: additional,
    );
  }

  /// Convert to Map for backward compatibility
  Map<String, dynamic> toMap() => <String, dynamic>{
        'threshold': threshold,
        ...additionalOptions,
      };
}

/// Server configuration options with proper typing
class ServerOptionsModel {
  /// The ping timeout duration
  final TimeoutDuration pingTimeout;

  /// The ping interval duration
  final TimeoutDuration pingInterval;

  /// The upgrade timeout duration
  final TimeoutDuration upgradeTimeout;

  /// Maximum buffer size for HTTP requests in bytes
  final double maxHttpBufferSize;

  /// List of allowed transports
  final List<TransportName> transports;

  /// Whether to allow transport upgrades
  final bool allowUpgrades;

  /// Custom request verification function
  final AllowRequestCallback? allowRequest;

  /// Cookie configuration
  final CookieConfig cookie;

  /// Cookie path configuration
  final CookiePathConfig cookiePath;

  /// Whether cookie should be HTTP only
  final bool cookieHttpOnly;

  /// Per-message deflate configuration
  final PerMessageDeflateConfig perMessageDeflate;

  /// HTTP compression configuration
  final HttpCompressionConfig httpCompression;

  /// Initial packet to send (can be any serializable data)
  final Object? initialPacket;

  /// Path for the engine.io endpoint
  final UrlPath path;

  ServerOptionsModel({
    final TimeoutDuration? pingTimeout,
    final TimeoutDuration? pingInterval,
    final TimeoutDuration? upgradeTimeout,
    this.maxHttpBufferSize = 10E7,
    this.transports = const <TransportName>[TransportName.polling, TransportName.websocket],
    this.allowUpgrades = true,
    this.allowRequest,
    final CookieConfig? cookie,
    final CookiePathConfig? cookiePath,
    this.cookieHttpOnly = true,
    final PerMessageDeflateConfig? perMessageDeflate,
    final HttpCompressionConfig? httpCompression,
    this.initialPacket,
    final UrlPath? path,
  })  : pingTimeout = pingTimeout ?? TimeoutDuration.milliseconds(60000),
        pingInterval = pingInterval ?? TimeoutDuration.milliseconds(25000),
        upgradeTimeout = upgradeTimeout ?? TimeoutDuration.milliseconds(10000),
        cookie = cookie ?? const EnabledCookie('io'),
        cookiePath = cookiePath ?? const EnabledCookiePath('/'),
        perMessageDeflate = perMessageDeflate ?? const PerMessageDeflateConfig(),
        httpCompression = httpCompression ?? const HttpCompressionConfig(),
        path = path ?? UrlPath('/engine.io');

  /// Create ServerOptionsModel from a Map (for backward compatibility)
  factory ServerOptionsModel.fromMap(final Map<String, dynamic>? opts) {
    final Map<String, dynamic> options = opts ?? <String, dynamic>{};

    // Handle perMessageDeflate
    final PerMessageDeflateConfig perMessageDeflate;
    if (!options.containsKey('perMessageDeflate') || options['perMessageDeflate'] == true) {
      final dynamic deflateValue = options['perMessageDeflate'];
      if (deflateValue is Map) {
        perMessageDeflate = PerMessageDeflateConfig.fromMap(Map<String, dynamic>.from(deflateValue));
      } else {
        perMessageDeflate = const PerMessageDeflateConfig();
      }
    } else {
      perMessageDeflate = const PerMessageDeflateConfig(threshold: 1024);
    }

    // Handle httpCompression
    final HttpCompressionConfig httpCompression = options['httpCompression'] is Map
        ? HttpCompressionConfig.fromMap(Map<String, dynamic>.from(options['httpCompression'] as Map<dynamic, dynamic>))
        : const HttpCompressionConfig();

    // Handle transports
    final List<TransportName> transports = options['transports'] is List
        ? (options['transports'] as List<dynamic>)
            .map((final dynamic t) => TransportName.fromString(t.toString()))
            .toList()
        : const <TransportName>[TransportName.polling, TransportName.websocket];

    return ServerOptionsModel(
      pingTimeout: TimeoutDuration.milliseconds(options['pingTimeout'] as int? ?? 60000),
      pingInterval: TimeoutDuration.milliseconds(options['pingInterval'] as int? ?? 25000),
      upgradeTimeout: TimeoutDuration.milliseconds(options['upgradeTimeout'] as int? ?? 10000),
      maxHttpBufferSize: options['maxHttpBufferSize'] as double? ?? 10E7,
      transports: transports,
      allowUpgrades: options['allowUpgrades'] != false,
      allowRequest: options['allowRequest'] as AllowRequestCallback?,
      cookie: CookieConfig.fromDynamic(options['cookie'] ?? 'io'),
      cookiePath: CookiePathConfig.fromDynamic(options['cookiePath'] ?? '/'),
      cookieHttpOnly: options['cookieHttpOnly'] != false,
      perMessageDeflate: perMessageDeflate,
      httpCompression: httpCompression,
      initialPacket: options['initialPacket'],
      path: UrlPath(options['path'] as String? ?? '/engine.io'),
    );
  }

  /// Convert back to Map for backward compatibility
  Map<String, dynamic> toMap() => <String, dynamic>{
        'pingTimeout': pingTimeout.inMilliseconds,
        'pingInterval': pingInterval.inMilliseconds,
        'upgradeTimeout': upgradeTimeout.inMilliseconds,
        'maxHttpBufferSize': maxHttpBufferSize,
        'transports': transports.map((final TransportName t) => t.value).toList(),
        'allowUpgrades': allowUpgrades,
        'allowRequest': allowRequest,
        'cookie': cookie.toCompatibility(),
        'cookiePath': cookiePath.toCompatibility(),
        'cookieHttpOnly': cookieHttpOnly,
        'perMessageDeflate': perMessageDeflate.toMap(),
        'httpCompression': httpCompression.toMap(),
        'initialPacket': initialPacket,
        'path': path.value,
      };
}

/// Attachment options for server configuration
class AttachmentOptionsModel {
  /// Path for the engine.io endpoint
  final UrlPath path;

  /// Additional custom options
  final Map<String, Object?> custom;

  AttachmentOptionsModel({
    final UrlPath? path,
    this.custom = const <String, Object?>{},
  }) : path = path ?? UrlPath('/engine.io');

  factory AttachmentOptionsModel.fromMap(final Map<String, dynamic>? opts) {
    final Map<String, dynamic> options = opts ?? <String, dynamic>{};
    final String pathValue = options['path'] as String? ?? '/engine.io';
    final Map<String, Object?> custom = Map<String, Object?>.from(options)..remove('path');

    return AttachmentOptionsModel(
      path: UrlPath(pathValue),
      custom: custom,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'path': path.value,
        ...custom,
      };
}
