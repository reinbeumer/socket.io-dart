/// Specific data models for Socket.IO packet payloads.
///
/// These models replace generic `Map<String, dynamic>` and `List<dynamic>`
/// usage in packet data fields with type-safe alternatives.
///
/// Copyright (C) 2024. All Rights Reserved.
library packet_data_models;

import '../value_objects/disconnect_reason_vo.dart';
import '../value_objects/event_arguments_vo.dart';

/// Data model for CONNECT packet payload.
///
/// Contains authentication and connection metadata.
/// In Socket.IO v3+, the server sends the socket ID in the CONNECT response.
///
/// Example:
/// ```dart
/// // Client request
/// final ConnectPacketData data = ConnectPacketData(
///   auth: {'token': 'abc123'},
///   query: {'userId': '123'},
/// );
///
/// // Server response
/// final ConnectPacketData response = ConnectPacketData(
///   sid: 'abc123xyz',
/// );
/// ```
class ConnectPacketData {
  /// Socket ID (sent by server in CONNECT response for Socket.IO v3+)
  final String? sid;

  /// Process ID (optional, for server identification)
  final String? pid;

  /// Authentication data.
  final Map<String, Object?>? auth;

  /// Query parameters.
  final Map<String, Object?>? query;

  /// Additional connection metadata.
  final Map<String, Object?>? metadata;

  /// Creates a new connect packet data model.
  const ConnectPacketData({
    this.sid,
    this.pid,
    this.auth,
    this.query,
    this.metadata,
  });

  /// Creates from a JSON map.
  factory ConnectPacketData.fromJson(final Map<String, dynamic> json) => ConnectPacketData(
        sid: json['sid'] as String?,
        pid: json['pid'] as String?,
        auth: json['auth'] as Map<String, Object?>?,
        query: json['query'] as Map<String, Object?>?,
        metadata: json['metadata'] as Map<String, Object?>?,
      );

  /// Converts to JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = <String, dynamic>{};
    if (sid != null) {
      result['sid'] = sid;
    }
    if (pid != null) {
      result['pid'] = pid;
    }
    if (auth != null) {
      result['auth'] = auth;
    }
    if (query != null) {
      result['query'] = query;
    }
    if (metadata != null) {
      result['metadata'] = metadata;
    }
    return result;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConnectPacketData &&
          runtimeType == other.runtimeType &&
          sid == other.sid &&
          pid == other.pid &&
          _mapEquals(auth, other.auth) &&
          _mapEquals(query, other.query) &&
          _mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(sid, pid, auth, query, metadata);

  @override
  String toString() => 'ConnectPacketData(sid: $sid, pid: $pid, auth: $auth, query: $query)';

  /// Helper to compare maps.
  static bool _mapEquals(
    final Map<String, Object?>? a,
    final Map<String, Object?>? b,
  ) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

/// Data model for DISCONNECT packet payload.
///
/// Contains the reason for disconnection and optional metadata.
///
/// Example:
/// ```dart
/// final DisconnectPacketData data = DisconnectPacketData(
///   reason: 'client disconnect',
///   description: 'User logged out',
/// );
/// ```
/// Data model for DISCONNECT packet payload.
///
/// Contains the reason for disconnection using type-safe DisconnectReason value object.
///
/// Example:
/// ```dart
/// // Using typed disconnect reason
/// final DisconnectPacketData data = DisconnectPacketData(
///   reason: DisconnectReason.clientDisconnect,
/// );
///
/// // Using string (backward compatible)
/// final DisconnectPacketData data2 = DisconnectPacketData.fromString('client disconnect');
/// ```
class DisconnectPacketData {
  /// The typed reason for disconnection (preferred).
  final DisconnectReason? typedReason;

  /// The string reason for disconnection (private, for backward compatibility).
  /// Note: This is private and only used internally for the deprecated constructor.
  final String? _rawReason;

  /// Optional human-readable description.
  final String? description;

  /// Additional metadata.
  final Map<String, Object?>? metadata;

  /// Creates a new disconnect packet data model with typed reason (preferred).
  const DisconnectPacketData({
    required final DisconnectReason reason,
    this.description,
    this.metadata,
  })  : typedReason = reason,
        _rawReason = null;

  /// Creates from a string reason (deprecated, for backward compatibility).
  @Deprecated('Use DisconnectPacketData() with DisconnectReason instead')
  const DisconnectPacketData.fromString({
    required final String reason,
    this.description,
    this.metadata,
  })  : _rawReason = reason,
        typedReason = null;

  /// Creates from a string reason (factory version).
  factory DisconnectPacketData.fromReasonString(final String reason) =>
      DisconnectPacketData(reason: DisconnectReason.fromString(reason));

  /// Creates from a JSON value.
  factory DisconnectPacketData.fromJson(final Object? json) {
    if (json is String) {
      return DisconnectPacketData(reason: DisconnectReason.fromString(json));
    }
    if (json is Map<String, dynamic>) {
      final String reasonStr = json['reason'] as String? ?? 'unknown';
      return DisconnectPacketData(
        reason: DisconnectReason.fromString(reasonStr),
        description: json['description'] as String?,
        metadata: json['metadata'] as Map<String, Object?>?,
      );
    }
    return DisconnectPacketData(
      reason: DisconnectReason.fromString(json?.toString() ?? 'unknown'),
    );
  }

  /// Gets the reason string value.
  String get reason {
    if (typedReason != null) {
      return typedReason!.value;
    }
    return _rawReason ?? 'unknown';
  }

  /// Gets the typed reason (creates from raw if needed).
  DisconnectReason get reasonValue {
    if (typedReason != null) {
      return typedReason!;
    }
    return DisconnectReason.fromString(_rawReason ?? 'unknown');
  }

  /// Converts to JSON.
  Object toJson() {
    if (description == null && metadata == null) {
      return reason;
    }
    final Map<String, dynamic> result = <String, dynamic>{'reason': reason};
    if (description != null) {
      result['description'] = description;
    }
    if (metadata != null) {
      result['metadata'] = metadata;
    }
    return result;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is DisconnectPacketData &&
          runtimeType == other.runtimeType &&
          reason == other.reason &&
          description == other.description &&
          ConnectPacketData._mapEquals(metadata, other.metadata);

  @override
  int get hashCode => Object.hash(reason, description, metadata);

  @override
  String toString() => 'DisconnectPacketData($reason)';
}

/// Data model for EVENT packet payload.
///
/// Contains the event name and arguments.
///
/// Example:
/// ```dart
/// final EventPacketData data = EventPacketData(
///   eventName: 'message',
///   arguments: EventArguments(['Hello', 42]),
/// );
/// ```
class EventPacketData {
  /// The name of the event.
  final String eventName;

  /// The event arguments.
  final EventArguments arguments;

  /// Creates a new event packet data model.
  const EventPacketData({
    required this.eventName,
    required this.arguments,
  });

  /// Creates from a list where first element is event name.
  factory EventPacketData.fromList(final List<dynamic> list) {
    if (list.isEmpty) {
      throw ArgumentError('Event data list cannot be empty');
    }
    final String eventName = list.first.toString();
    final List<Object?> args = list.length > 1 ? list.sublist(1).cast<Object?>() : <Object?>[];
    return EventPacketData(
      eventName: eventName,
      arguments: EventArguments(args),
    );
  }

  /// Creates with no arguments.
  factory EventPacketData.withoutArgs(final String eventName) => EventPacketData(
        eventName: eventName,
        arguments: EventArguments.empty(),
      );

  /// Creates with a single argument.
  factory EventPacketData.single(final String eventName, final Object? value) => EventPacketData(
        eventName: eventName,
        arguments: EventArguments.single(value),
      );

  /// Converts to a list format (event name followed by arguments).
  List<Object?> toList() => <Object?>[eventName, ...arguments.arguments];

  /// Converts to JSON.
  List<Object?> toJson() => toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EventPacketData &&
          runtimeType == other.runtimeType &&
          eventName == other.eventName &&
          arguments == other.arguments;

  @override
  int get hashCode => Object.hash(eventName, arguments);

  @override
  String toString() => 'EventPacketData($eventName, ${arguments.length} args)';
}

/// Data model for ACK (acknowledgment) packet payload.
///
/// Contains the response arguments to an event with callback.
///
/// Example:
/// ```dart
/// final AckPacketData data = AckPacketData(
///   arguments: EventArguments(['success', {'status': 200}]),
/// );
/// ```
class AckPacketData {
  /// The acknowledgment arguments.
  final EventArguments arguments;

  /// Creates a new ACK packet data model.
  const AckPacketData({
    required this.arguments,
  });

  /// Creates from a list of arguments.
  factory AckPacketData.fromList(final List<dynamic> list) => AckPacketData(
        arguments: EventArguments(list.cast<Object?>()),
      );

  /// Creates with no arguments (simple acknowledgment).
  factory AckPacketData.empty() => AckPacketData(arguments: EventArguments.empty());

  /// Creates with a single argument.
  factory AckPacketData.single(final Object? value) => AckPacketData(arguments: EventArguments.single(value));

  /// Creates success acknowledgment with optional data.
  factory AckPacketData.success([final Object? data]) {
    if (data == null) {
      return AckPacketData(arguments: EventArguments.empty());
    }
    return AckPacketData(arguments: EventArguments.single(data));
  }

  /// Creates error acknowledgment.
  factory AckPacketData.error(final Object error) => AckPacketData(arguments: EventArguments.single(error));

  /// Converts to a list format.
  List<Object?> toList() => arguments.arguments;

  /// Converts to JSON.
  List<Object?> toJson() => toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is AckPacketData && runtimeType == other.runtimeType && arguments == other.arguments;

  @override
  int get hashCode => arguments.hashCode;

  @override
  String toString() => 'AckPacketData(${arguments.length} args)';
}

/// Data model for CONNECT_ERROR packet payload.
///
/// Contains error information when connection to a namespace fails.
///
/// Example:
/// ```dart
/// final ConnectErrorPacketData data = ConnectErrorPacketData(
///   message: 'Authentication failed',
///   code: 'AUTH_ERROR',
///   details: {'reason': 'Invalid token'},
/// );
/// ```
class ConnectErrorPacketData {
  /// The error message.
  final String message;

  /// Optional error code.
  final String? code;

  /// Additional error details.
  final Map<String, Object?>? details;

  /// Creates a new connect error packet data model.
  const ConnectErrorPacketData({
    required this.message,
    this.code,
    this.details,
  });

  /// Creates from a string message.
  factory ConnectErrorPacketData.fromMessage(final String message) => ConnectErrorPacketData(message: message);

  /// Creates from a JSON value.
  factory ConnectErrorPacketData.fromJson(final Object? json) {
    if (json is String) {
      return ConnectErrorPacketData(message: json);
    }
    if (json is Map<String, dynamic>) {
      return ConnectErrorPacketData(
        message: json['message'] as String? ?? 'Connection error',
        code: json['code'] as String?,
        details: json['details'] as Map<String, Object?>?,
      );
    }
    return ConnectErrorPacketData(message: json?.toString() ?? 'Unknown error');
  }

  /// Converts to JSON.
  Object toJson() {
    if (code == null && details == null) {
      return message;
    }
    final Map<String, dynamic> result = <String, dynamic>{'message': message};
    if (code != null) {
      result['code'] = code;
    }
    if (details != null) {
      result['details'] = details;
    }
    return result;
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConnectErrorPacketData &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code &&
          ConnectPacketData._mapEquals(details, other.details);

  @override
  int get hashCode => Object.hash(message, code, details);

  @override
  String toString() => 'ConnectErrorPacketData($message)';
}
