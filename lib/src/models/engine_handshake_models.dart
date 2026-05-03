/// engine_handshake_models.dart
///
/// Models for Engine.IO handshake data to replace dynamic usage
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library engine_handshake_models;

/// Engine.IO handshake response data sent to client upon successful connection
///
/// Contains session ID, available transport upgrades, and ping configuration
class EngineHandshakeData {
  /// Session ID assigned to the socket
  final String sid;

  /// List of available transport upgrade paths (e.g., ['websocket'])
  final List<String> upgrades;

  /// Server ping interval in milliseconds
  final int pingInterval;

  /// Server ping timeout in milliseconds
  final int pingTimeout;

  /// Maximum HTTP buffer size (optional, polling transport only)
  final int? maxHttpBufferSize;

  const EngineHandshakeData({
    required this.sid,
    required this.upgrades,
    required this.pingInterval,
    required this.pingTimeout,
    this.maxHttpBufferSize,
  });

  /// Creates handshake data from JSON map
  factory EngineHandshakeData.fromJson(final Map<String, dynamic> json) => EngineHandshakeData(
        sid: json['sid'] as String,
        upgrades: (json['upgrades'] as List<dynamic>).map((final dynamic e) => e.toString()).toList(),
        pingInterval: json['pingInterval'] as int,
        pingTimeout: json['pingTimeout'] as int,
        maxHttpBufferSize: json['maxHttpBufferSize'] as int?,
      );

  /// Converts handshake data to JSON map
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'sid': sid,
      'upgrades': upgrades,
      'pingInterval': pingInterval,
      'pingTimeout': pingTimeout,
    };
    if (maxHttpBufferSize != null) {
      json['maxHttpBufferSize'] = maxHttpBufferSize;
    }
    return json;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EngineHandshakeData &&
          runtimeType == other.runtimeType &&
          sid == other.sid &&
          _listEquals(upgrades, other.upgrades) &&
          pingInterval == other.pingInterval &&
          pingTimeout == other.pingTimeout &&
          maxHttpBufferSize == other.maxHttpBufferSize;

  @override
  int get hashCode =>
      sid.hashCode ^
      upgrades.hashCode ^
      pingInterval.hashCode ^
      pingTimeout.hashCode ^
      (maxHttpBufferSize?.hashCode ?? 0);

  @override
  String toString() =>
      'EngineHandshakeData(sid: $sid, upgrades: $upgrades, pingInterval: $pingInterval, pingTimeout: $pingTimeout, maxHttpBufferSize: $maxHttpBufferSize)';

  /// Helper for list equality
  bool _listEquals(final List<String> a, final List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Engine.IO handshake request data from client
///
/// Contains client configuration and preferences
class EngineHandshakeRequest {
  /// Transport type requested (e.g., 'websocket', 'polling')
  final String transport;

  /// Whether client supports binary data (false if b64=1 query parameter)
  final bool supportsBinary;

  /// Engine.IO protocol version (e.g., '4', '3')
  final String? eid;

  /// Optional session ID for reconnection
  final String? sid;

  const EngineHandshakeRequest({
    required this.transport,
    this.supportsBinary = true,
    this.eid,
    this.sid,
  });

  /// Creates handshake request from query parameters
  factory EngineHandshakeRequest.fromQuery(
    final Map<String, dynamic> queryParams,
  ) =>
      EngineHandshakeRequest(
        transport: queryParams['transport'] as String? ?? 'polling',
        supportsBinary: queryParams['b64'] != '1',
        eid: queryParams['EIO'] as String?,
        sid: queryParams['sid'] as String?,
      );

  /// Whether this is a reconnection request (has sid)
  bool get isReconnection => sid != null;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EngineHandshakeRequest &&
          runtimeType == other.runtimeType &&
          transport == other.transport &&
          supportsBinary == other.supportsBinary &&
          eid == other.eid &&
          sid == other.sid;

  @override
  int get hashCode => transport.hashCode ^ supportsBinary.hashCode ^ (eid?.hashCode ?? 0) ^ (sid?.hashCode ?? 0);

  @override
  String toString() =>
      'EngineHandshakeRequest(transport: $transport, supportsBinary: $supportsBinary, eid: $eid, sid: $sid, isReconnection: $isReconnection)';
}
