/// disconnect_reason_vo.dart
///
/// Value object for disconnect reason with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library disconnect_reason_vo;

/// Enumeration of standard disconnect reasons.
enum DisconnectReasonType {
  /// Client initiated disconnect.
  clientDisconnect,

  /// Server initiated disconnect.
  serverDisconnect,

  /// Connection timeout.
  pingTimeout,

  /// Transport closed.
  transportClose,

  /// Transport error.
  transportError,

  /// Parse error.
  parseError,

  /// Forced server closure.
  forcedClose,

  /// Invalid namespace.
  invalidNamespace,

  /// IO server disconnect.
  ioServerDisconnect,

  /// IO client disconnect.
  ioClientDisconnect,
}

/// Extension methods for DisconnectReasonType.
extension DisconnectReasonTypeExtension on DisconnectReasonType {
  /// Returns the string representation.
  String get value {
    switch (this) {
      case DisconnectReasonType.clientDisconnect:
        return 'client disconnect';
      case DisconnectReasonType.serverDisconnect:
        return 'server disconnect';
      case DisconnectReasonType.pingTimeout:
        return 'ping timeout';
      case DisconnectReasonType.transportClose:
        return 'transport close';
      case DisconnectReasonType.transportError:
        return 'transport error';
      case DisconnectReasonType.parseError:
        return 'parse error';
      case DisconnectReasonType.forcedClose:
        return 'forced close';
      case DisconnectReasonType.invalidNamespace:
        return 'invalid namespace';
      case DisconnectReasonType.ioServerDisconnect:
        return 'io server disconnect';
      case DisconnectReasonType.ioClientDisconnect:
        return 'io client disconnect';
    }
  }
}

/// Helper class for DisconnectReasonType.
class DisconnectReasonTypeHelper {
  /// Creates from string.
  static DisconnectReasonType fromString(final String reason) {
    switch (reason.toLowerCase().trim()) {
      case 'client disconnect':
        return DisconnectReasonType.clientDisconnect;
      case 'server disconnect':
        return DisconnectReasonType.serverDisconnect;
      case 'ping timeout':
        return DisconnectReasonType.pingTimeout;
      case 'transport close':
        return DisconnectReasonType.transportClose;
      case 'transport error':
        return DisconnectReasonType.transportError;
      case 'parse error':
        return DisconnectReasonType.parseError;
      case 'forced close':
        return DisconnectReasonType.forcedClose;
      case 'invalid namespace':
        return DisconnectReasonType.invalidNamespace;
      case 'io server disconnect':
        return DisconnectReasonType.ioServerDisconnect;
      case 'io client disconnect':
        return DisconnectReasonType.ioClientDisconnect;
      default:
        throw ArgumentError('Unknown disconnect reason: $reason');
    }
  }
}

/// Value object representing a disconnect reason.
class DisconnectReason {
  final DisconnectReasonType type;
  final String? details;

  const DisconnectReason._(this.type, this.details);

  /// Creates a DisconnectReason from a type.
  const DisconnectReason(this.type, [this.details]);

  /// Creates from string.
  factory DisconnectReason.fromString(final String reason) {
    try {
      return DisconnectReason(DisconnectReasonTypeHelper.fromString(reason));
    } catch (_) {
      // If not a standard reason, create a custom one
      return DisconnectReason(DisconnectReasonType.serverDisconnect, reason);
    }
  }

  /// Common disconnect reasons as constants.
  static const DisconnectReason clientDisconnect = DisconnectReason._(DisconnectReasonType.clientDisconnect, null);
  static const DisconnectReason serverDisconnect = DisconnectReason._(DisconnectReasonType.serverDisconnect, null);
  static const DisconnectReason pingTimeout = DisconnectReason._(DisconnectReasonType.pingTimeout, null);
  static const DisconnectReason transportClose = DisconnectReason._(DisconnectReasonType.transportClose, null);
  static const DisconnectReason transportError = DisconnectReason._(DisconnectReasonType.transportError, null);

  /// Returns the string value.
  String get value => details ?? type.value;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is DisconnectReason && runtimeType == other.runtimeType && type == other.type && details == other.details;

  @override
  int get hashCode => Object.hash(type, details);

  @override
  String toString() => value;
}
