/// transport_name_vo.dart
///
/// Value object for transport name with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library transport_name_vo;

/// Enumeration of valid transport types.
enum TransportType {
  websocket,
  polling,
  webtransport,
}

/// Extension methods for TransportType.
extension TransportTypeExtension on TransportType {
  /// Returns the string representation.
  String get value {
    switch (this) {
      case TransportType.websocket:
        return 'websocket';
      case TransportType.polling:
        return 'polling';
      case TransportType.webtransport:
        return 'webtransport';
    }
  }
}

/// Helper class for TransportType.
class TransportTypeHelper {
  /// Creates from string.
  static TransportType fromString(final String name) {
    switch (name.toLowerCase()) {
      case 'websocket':
      case 'ws':
        return TransportType.websocket;
      case 'polling':
        return TransportType.polling;
      case 'webtransport':
        return TransportType.webtransport;
      default:
        throw ArgumentError('Invalid transport type: $name');
    }
  }
}

/// Value object representing a validated transport name.
class TransportName {
  final TransportType type;

  const TransportName._(this.type);

  /// Creates a TransportName from a transport type.
  const TransportName(this.type);

  /// Creates from string.
  factory TransportName.fromString(final String name) => TransportName(TransportTypeHelper.fromString(name));

  /// Creates a WebSocket transport name.
  static const TransportName websocket = TransportName._(TransportType.websocket);

  /// Creates a Polling transport name.
  static const TransportName polling = TransportName._(TransportType.polling);

  /// Creates a WebTransport transport name.
  static const TransportName webtransport = TransportName._(TransportType.webtransport);

  /// Returns the string value.
  String get value => type.value;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is TransportName && runtimeType == other.runtimeType && type == other.type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => value;
}
