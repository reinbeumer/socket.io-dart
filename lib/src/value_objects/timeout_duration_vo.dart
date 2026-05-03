/// timeout_duration_vo.dart
///
/// Value object for timeout duration with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library timeout_duration_vo;

/// Value object representing a validated timeout duration.
class TimeoutDuration {
  final Duration value;

  const TimeoutDuration._(this.value);

  /// Creates a TimeoutDuration from a Duration with validation.
  ///
  /// Throws [ArgumentError] if the duration is negative or too long.
  factory TimeoutDuration(final Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError('Timeout duration cannot be negative');
    }
    if (duration.inSeconds > 3600) {
      // Max 1 hour
      throw ArgumentError('Timeout duration cannot exceed 1 hour');
    }
    return TimeoutDuration._(duration);
  }

  /// Creates from milliseconds.
  factory TimeoutDuration.milliseconds(final int milliseconds) => TimeoutDuration(Duration(milliseconds: milliseconds));

  /// Creates from seconds.
  factory TimeoutDuration.seconds(final int seconds) => TimeoutDuration(Duration(seconds: seconds));

  /// Creates from minutes.
  factory TimeoutDuration.minutes(final int minutes) => TimeoutDuration(Duration(minutes: minutes));

  /// Creates without validation (use with caution).
  const TimeoutDuration.unchecked(this.value);

  /// Default connection timeout (20 seconds).
  static final TimeoutDuration defaultConnection = TimeoutDuration.seconds(20);

  /// Default ping timeout (5 seconds).
  static final TimeoutDuration defaultPing = TimeoutDuration.seconds(5);

  /// Returns duration in milliseconds.
  int get inMilliseconds => value.inMilliseconds;

  /// Returns duration in seconds.
  int get inSeconds => value.inSeconds;

  /// Adds two TimeoutDurations together.
  TimeoutDuration operator +(final TimeoutDuration other) => TimeoutDuration.unchecked(value + other.value);

  /// Subtracts one TimeoutDuration from another.
  TimeoutDuration operator -(final TimeoutDuration other) => TimeoutDuration.unchecked(value - other.value);

  /// Multiplies the duration by a factor.
  TimeoutDuration operator *(final int factor) => TimeoutDuration.unchecked(value * factor);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is TimeoutDuration && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  /// Converts to JSON (milliseconds as int for Engine.IO protocol).
  int toJson() => inMilliseconds;

  @override
  String toString() => '${value.inMilliseconds}ms';
}
