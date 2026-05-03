/// duration_extensions.dart
///
/// Extension methods for Duration operations including timeout validation
/// and millisecond conversions.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library duration_extensions;

/// Extension methods for Duration
extension DurationExtensions on Duration {
  /// Converts Duration to milliseconds as int
  int get inWholeMilliseconds => inMilliseconds;

  /// Checks if duration is valid for a timeout (non-negative)
  bool get isValidTimeout => !isNegative;

  /// Checks if duration is within a reasonable timeout range
  /// (between 0 and 1 hour by default)
  bool isWithinTimeoutRange({final Duration max = const Duration(hours: 1)}) => !isNegative && this <= max;

  /// Creates a human-readable string representation
  String toHumanReadable() {
    if (inDays > 0) {
      return '$inDays day${inDays == 1 ? '' : 's'}';
    } else if (inHours > 0) {
      return '$inHours hour${inHours == 1 ? '' : 's'}';
    } else if (inMinutes > 0) {
      return '$inMinutes minute${inMinutes == 1 ? '' : 's'}';
    } else if (inSeconds > 0) {
      return '$inSeconds second${inSeconds == 1 ? '' : 's'}';
    } else {
      return '${inMilliseconds}ms';
    }
  }

  /// Creates a compact string representation (e.g., "1d", "2h", "30m", "45s", "100ms")
  String toCompact() {
    if (inDays > 0) {
      return '${inDays}d';
    } else if (inHours > 0) {
      return '${inHours}h';
    } else if (inMinutes > 0) {
      return '${inMinutes}m';
    } else if (inSeconds > 0) {
      return '${inSeconds}s';
    } else {
      return '${inMilliseconds}ms';
    }
  }

  /// Clamps duration between min and max values
  Duration clamp(final Duration min, final Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Multiplies duration by a factor
  Duration operator *(final num factor) => Duration(microseconds: (inMicroseconds * factor).round());

  /// Divides duration by a factor
  Duration operator /(final num factor) => Duration(microseconds: (inMicroseconds / factor).round());

  /// Checks if duration is approximately equal to another within tolerance
  bool isApproximately(final Duration other, {final Duration tolerance = const Duration(milliseconds: 1)}) =>
      (this - other).abs() <= tolerance;

  /// Returns the absolute value of the duration
  Duration abs() => isNegative ? -this : this;
}

/// Extension methods for int representing milliseconds
extension IntToDuration on int {
  /// Converts milliseconds (as int) to Duration
  Duration get milliseconds => Duration(milliseconds: this);

  /// Converts seconds (as int) to Duration
  Duration get seconds => Duration(seconds: this);

  /// Converts minutes (as int) to Duration
  Duration get minutes => Duration(minutes: this);

  /// Converts hours (as int) to Duration
  Duration get hours => Duration(hours: this);

  /// Converts days (as int) to Duration
  Duration get days => Duration(days: this);

  /// Checks if millisecond value is a valid timeout (non-negative)
  bool get isValidTimeoutMs => this >= 0;

  /// Checks if millisecond value is within reasonable timeout range
  bool get isReasonableTimeoutMs => this >= 0 && this <= const Duration(hours: 1).inMilliseconds;
}

/// Extension methods for double representing milliseconds
extension DoubleToDuration on double {
  /// Converts milliseconds (as double) to Duration
  Duration get milliseconds => Duration(microseconds: (this * 1000).round());

  /// Converts seconds (as double) to Duration
  Duration get seconds => Duration(microseconds: (this * 1000000).round());

  /// Converts minutes (as double) to Duration
  Duration get minutes => Duration(microseconds: (this * 60000000).round());

  /// Converts hours (as double) to Duration
  Duration get hours => Duration(microseconds: (this * 3600000000).round());

  /// Converts days (as double) to Duration
  Duration get days => Duration(microseconds: (this * 86400000000).round());
}

/// Utility class for common timeout durations
class TimeoutDurations {
  TimeoutDurations._();

  /// No timeout (Duration.zero)
  static const Duration none = Duration.zero;

  /// Very short timeout (100ms)
  static const Duration veryShort = Duration(milliseconds: 100);

  /// Short timeout (1 second)
  static const Duration short = Duration(seconds: 1);

  /// Medium timeout (5 seconds)
  static const Duration medium = Duration(seconds: 5);

  /// Default timeout (30 seconds)
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Long timeout (1 minute)
  static const Duration long = Duration(minutes: 1);

  /// Very long timeout (5 minutes)
  static const Duration veryLong = Duration(minutes: 5);

  /// Extremely long timeout (30 minutes)
  static const Duration extreme = Duration(minutes: 30);

  /// Maximum reasonable timeout (1 hour)
  static const Duration maximum = Duration(hours: 1);

  /// Connection timeout (typically 20 seconds)
  static const Duration connection = Duration(seconds: 20);

  /// Handshake timeout (typically 10 seconds)
  static const Duration handshake = Duration(seconds: 10);

  /// Keep-alive interval (typically 25 seconds)
  static const Duration keepAlive = Duration(seconds: 25);

  /// Ping interval (typically 25 seconds)
  static const Duration ping = Duration(seconds: 25);

  /// Ping timeout (typically 60 seconds)
  static const Duration pingTimeout = Duration(seconds: 60);

  /// Reconnection delay (typically 1 second)
  static const Duration reconnection = Duration(seconds: 1);

  /// HTTP request timeout (typically 30 seconds)
  static const Duration httpRequest = Duration(seconds: 30);
}
