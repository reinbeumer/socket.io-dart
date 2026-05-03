/// Value object for error codes in Socket.IO.
///
/// Wraps error codes with validation to ensure they are in valid format.
/// Supports both numeric codes (e.g., 1001, 2001) and string codes (e.g., 'AUTH_ERROR').
///
/// Copyright (C) 2024. All Rights Reserved.
library error_code_vo;

import 'package:meta/meta.dart';

/// Value object representing an error code.
///
/// Error codes can be:
/// - Numeric: HTTP-style codes (e.g., 400, 404, 1001, 2001)
/// - String: Named error codes (e.g., 'AUTH_ERROR', 'CONNECTION_FAILED')
///
/// Example:
/// ```dart
/// // Numeric error code
/// final ErrorCode numericCode = ErrorCode.numeric(1001);
/// print(numericCode.value); // '1001'
/// print(numericCode.isNumeric); // true
/// print(numericCode.numericValue); // 1001
///
/// // String error code
/// final ErrorCode stringCode = ErrorCode.string('AUTH_ERROR');
/// print(stringCode.value); // 'AUTH_ERROR'
/// print(stringCode.isNumeric); // false
///
/// // Auto-detect from string
/// final ErrorCode autoCode = ErrorCode('404');
/// print(autoCode.isNumeric); // true
/// print(autoCode.numericValue); // 404
/// ```
@immutable
class ErrorCode {
  /// The raw error code value.
  final String value;

  /// The numeric value, if the code is numeric.
  final int? _numericValue;

  /// Creates an error code value object.
  ///
  /// Validates that the code is not empty and is in a valid format.
  ///
  /// Throws [ArgumentError] if:
  /// - [value] is empty
  /// - [value] contains only whitespace
  factory ErrorCode(final String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('Error code cannot be empty');
    }

    final String trimmed = value.trim();

    // Check if it's a valid numeric code
    final int? numericValue = int.tryParse(trimmed);
    if (numericValue != null) {
      if (numericValue < 0) {
        throw ArgumentError('Numeric error code must be non-negative, got: $numericValue');
      }
      return ErrorCode._internal(trimmed, numericValue);
    }

    // String error code - validate format
    // Should be uppercase letters, numbers, underscores, and hyphens
    final RegExp validPattern = RegExp(r'^[A-Z0-9_\-]+$');
    if (!validPattern.hasMatch(trimmed.toUpperCase())) {
      throw ArgumentError(
        'String error code must contain only letters, numbers, underscores, and hyphens: $trimmed',
      );
    }

    return ErrorCode._internal(trimmed.toUpperCase(), null);
  }

  /// Creates a numeric error code.
  ///
  /// Throws [ArgumentError] if [code] is negative.
  factory ErrorCode.numeric(final int code) {
    if (code < 0) {
      throw ArgumentError('Numeric error code must be non-negative, got: $code');
    }
    return ErrorCode._internal(code.toString(), code);
  }

  /// Creates a string error code.
  ///
  /// The code will be normalized to uppercase.
  ///
  /// Throws [ArgumentError] if:
  /// - [code] is empty
  /// - [code] contains invalid characters
  factory ErrorCode.string(final String code) {
    if (code.trim().isEmpty) {
      throw ArgumentError('Error code cannot be empty');
    }

    final String normalized = code.trim().toUpperCase();

    // Validate format
    final RegExp validPattern = RegExp(r'^[A-Z0-9_\-]+$');
    if (!validPattern.hasMatch(normalized)) {
      throw ArgumentError(
        'String error code must contain only letters, numbers, underscores, and hyphens: $code',
      );
    }

    return ErrorCode._internal(normalized, null);
  }

  /// Private constructor.
  const ErrorCode._internal(this.value, this._numericValue);

  /// Unchecked constructor that bypasses validation.
  ///
  /// Use with caution - only when you're certain the value is valid.
  const ErrorCode.unchecked(this.value) : _numericValue = null;

  /// Whether this is a numeric error code.
  bool get isNumeric => _numericValue != null;

  /// Whether this is a string error code.
  bool get isString => !isNumeric;

  /// Gets the numeric value if this is a numeric code.
  ///
  /// Returns null if this is a string code.
  int? get numericValue => _numericValue;

  /// Common numeric error codes.
  ///
  /// Connection errors (1xxx)
  static final ErrorCode connectionTimeout = ErrorCode.numeric(1001);
  static final ErrorCode connectionRefused = ErrorCode.numeric(1002);
  static final ErrorCode connectionLost = ErrorCode.numeric(1003);
  static final ErrorCode connectionFailed = ErrorCode.numeric(1004);

  /// Transport errors (2xxx)
  static final ErrorCode transportError = ErrorCode.numeric(2001);
  static final ErrorCode transportClosed = ErrorCode.numeric(2002);
  static final ErrorCode transportTimeout = ErrorCode.numeric(2003);
  static final ErrorCode transportFailed = ErrorCode.numeric(2004);

  /// Protocol errors (3xxx)
  static final ErrorCode protocolError = ErrorCode.numeric(3001);
  static final ErrorCode invalidPacket = ErrorCode.numeric(3002);

  /// Authentication errors (4xxx)
  static final ErrorCode authenticationFailed = ErrorCode.numeric(4001);
  static final ErrorCode authorizationFailed = ErrorCode.numeric(4002);
  static final ErrorCode invalidCredentials = ErrorCode.numeric(4003);

  /// Unknown error
  static final ErrorCode unknown = ErrorCode.numeric(9999);

  /// Common string error codes.
  static final ErrorCode authError = ErrorCode.string('AUTH_ERROR');
  static final ErrorCode timeoutError = ErrorCode.string('TIMEOUT_ERROR');
  static final ErrorCode networkError = ErrorCode.string('NETWORK_ERROR');
  static final ErrorCode parseError = ErrorCode.string('PARSE_ERROR');
  static final ErrorCode invalidData = ErrorCode.string('INVALID_DATA');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is ErrorCode && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ErrorCode($value)';
}
