/// port_number_vo.dart
///
/// Value object for port number with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library port_number_vo;

/// Value object representing a validated port number.
///
/// Port numbers must be in the valid range (1-65535).
class PortNumber {
  final int value;

  const PortNumber._(this.value);

  /// Creates a PortNumber from an integer with validation.
  ///
  /// Throws [ArgumentError] if the port is outside valid range.
  factory PortNumber(final int port) {
    if (port < 1 || port > 65535) {
      throw ArgumentError('Port number must be between 1 and 65535, got: $port');
    }
    return PortNumber._(port);
  }

  /// Creates a PortNumber without validation (use with caution).
  const PortNumber.unchecked(this.value);

  /// Common HTTP port (80).
  static const PortNumber http = PortNumber.unchecked(80);

  /// Common HTTPS port (443).
  static const PortNumber https = PortNumber.unchecked(443);

  /// Common development port (3000).
  static const PortNumber dev = PortNumber.unchecked(3000);

  /// Common alternative HTTP port (8080).
  static const PortNumber altHttp = PortNumber.unchecked(8080);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is PortNumber && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}
