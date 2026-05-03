/// validation_error_models.dart
///
/// Models for validation errors throughout the Socket.IO codebase
///
/// Provides a type-safe way to represent validation failures
/// instead of throwing exceptions or returning null.
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library validation_error_models;

/// Base sealed class for all validation errors
///
/// Using sealed class ensures exhaustive pattern matching and makes
/// validation error handling explicit and type-safe.
sealed class ValidationError {
  /// The field or property that failed validation
  final String field;

  /// Human-readable error message
  final String message;

  /// Optional error code for programmatic handling
  final String? code;

  const ValidationError({
    required this.field,
    required this.message,
    this.code,
  });

  @override
  String toString() => 'ValidationError($field): $message${code != null ? ' [code: $code]' : ''}';
}

/// Validation error for required fields that are missing or null
final class RequiredFieldError extends ValidationError {
  const RequiredFieldError({
    required super.field,
    super.message = 'Required field is missing',
    super.code = 'required_field',
  });
}

/// Validation error for values that don't meet format requirements
final class FormatError extends ValidationError {
  /// The expected format description
  final String expectedFormat;

  /// The actual value that failed validation
  final Object? actualValue;

  const FormatError({
    required super.field,
    required this.expectedFormat,
    this.actualValue,
    super.message = 'Invalid format',
    super.code = 'invalid_format',
  });

  @override
  String toString() =>
      'FormatError($field): Expected $expectedFormat, got $actualValue${code != null ? ' [code: $code]' : ''}';
}

/// Validation error for values outside acceptable ranges
final class RangeValidationError extends ValidationError {
  /// The minimum acceptable value (if any)
  final num? min;

  /// The maximum acceptable value (if any)
  final num? max;

  /// The actual value that failed validation
  final num actualValue;

  const RangeValidationError({
    required super.field,
    this.min,
    this.max,
    required this.actualValue,
    super.message = 'Value out of range',
    super.code = 'out_of_range',
  });

  @override
  String toString() {
    final String rangeDesc = min != null && max != null
        ? 'between $min and $max'
        : min != null
            ? 'at least $min'
            : 'at most $max';
    return 'RangeValidationError($field): Expected $rangeDesc, got $actualValue${code != null ? ' [code: $code]' : ''}';
  }
}

/// Validation error for string length constraints
final class LengthError extends ValidationError {
  /// The minimum acceptable length (if any)
  final int? minLength;

  /// The maximum acceptable length (if any)
  final int? maxLength;

  /// The actual length that failed validation
  final int actualLength;

  const LengthError({
    required super.field,
    this.minLength,
    this.maxLength,
    required this.actualLength,
    super.message = 'Invalid length',
    super.code = 'invalid_length',
  });

  @override
  String toString() {
    final String lengthDesc = minLength != null && maxLength != null
        ? 'between $minLength and $maxLength characters'
        : minLength != null
            ? 'at least $minLength characters'
            : 'at most $maxLength characters';
    return 'LengthError($field): Expected $lengthDesc, got $actualLength${code != null ? ' [code: $code]' : ''}';
  }
}

/// Validation error for values not in allowed set
final class InvalidValueError extends ValidationError {
  /// The set of allowed values
  final List<Object?> allowedValues;

  /// The actual value that failed validation
  final Object? actualValue;

  const InvalidValueError({
    required super.field,
    required this.allowedValues,
    this.actualValue,
    super.message = 'Invalid value',
    super.code = 'invalid_value',
  });

  @override
  String toString() =>
      'InvalidValueError($field): Expected one of $allowedValues, got $actualValue${code != null ? ' [code: $code]' : ''}';
}

/// Validation error for custom business rules
final class CustomValidationError extends ValidationError {
  /// Additional context or details about the error
  final Map<String, Object?>? details;

  const CustomValidationError({
    required super.field,
    required super.message,
    super.code,
    this.details,
  });

  @override
  String toString() {
    final String detailsStr = details != null ? ', details: $details' : '';
    return 'CustomValidationError($field): $message$detailsStr${code != null ? ' [code: $code]' : ''}';
  }
}

/// Result type for validation operations
///
/// Represents either a successful validation (with value T)
/// or a validation failure (with list of errors).
sealed class ValidationResult<T> {
  const ValidationResult();

  /// Returns true if validation succeeded
  bool get isValid => this is ValidationSuccess<T>;

  /// Returns true if validation failed
  bool get isInvalid => this is ValidationFailure<T>;

  /// Gets the value if validation succeeded, throws if failed
  T get value {
    final ValidationResult<T> self = this;
    if (self is ValidationSuccess<T>) {
      return self.value;
    }
    throw StateError('Cannot get value from failed validation');
  }

  /// Gets the errors if validation failed, throws if succeeded
  List<ValidationError> get errors {
    final ValidationResult<T> self = this;
    if (self is ValidationFailure<T>) {
      return self.errors;
    }
    throw StateError('Cannot get errors from successful validation');
  }

  /// Gets the value if valid, otherwise returns the result of calling [orElse]
  T getOrElse(final T Function() orElse) {
    final ValidationResult<T> self = this;
    if (self is ValidationSuccess<T>) {
      return self.value;
    }
    return orElse();
  }

  /// Gets the value if valid, otherwise returns [defaultValue]
  T getOrDefault(final T defaultValue) {
    final ValidationResult<T> self = this;
    if (self is ValidationSuccess<T>) {
      return self.value;
    }
    return defaultValue;
  }

  /// Transforms the value if validation succeeded
  ValidationResult<R> map<R>(final R Function(T value) transform) {
    final ValidationResult<T> self = this;
    if (self is ValidationSuccess<T>) {
      return ValidationSuccess<R>(transform(self.value));
    }
    return ValidationFailure<R>((self as ValidationFailure<T>).errors);
  }

  /// Chains validation operations
  ValidationResult<R> flatMap<R>(final ValidationResult<R> Function(T value) transform) {
    final ValidationResult<T> self = this;
    if (self is ValidationSuccess<T>) {
      return transform(self.value);
    }
    return ValidationFailure<R>((self as ValidationFailure<T>).errors);
  }
}

/// Successful validation result
final class ValidationSuccess<T> extends ValidationResult<T> {
  @override
  final T value;

  const ValidationSuccess(this.value);

  @override
  String toString() => 'ValidationSuccess($value)';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ValidationSuccess<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed validation result
final class ValidationFailure<T> extends ValidationResult<T> {
  @override
  final List<ValidationError> errors;

  const ValidationFailure(this.errors);

  /// Creates a failure with a single error
  factory ValidationFailure.single(final ValidationError error) => ValidationFailure<T>(<ValidationError>[error]);

  @override
  String toString() =>
      'ValidationFailure(${errors.length} errors: ${errors.map((final ValidationError e) => e.toString()).join(', ')})';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ValidationFailure<T> &&
          runtimeType == other.runtimeType &&
          errors.length == other.errors.length &&
          errors.every(other.errors.contains);

  @override
  int get hashCode => Object.hashAll(errors);
}

/// Utility functions for validation
class ValidationUtils {
  ValidationUtils._();

  /// Validates that a value is not null
  static ValidationResult<T> required<T>(
    final T? value,
    final String field, {
    final String? message,
  }) {
    if (value == null) {
      return ValidationFailure<T>.single(
        RequiredFieldError(
          field: field,
          message: message ?? 'Required field is missing',
        ),
      );
    }
    return ValidationSuccess<T>(value);
  }

  /// Validates that a string is not empty
  static ValidationResult<String> nonEmpty(
    final String value,
    final String field, {
    final String? message,
  }) {
    if (value.isEmpty) {
      return ValidationFailure<String>.single(
        RequiredFieldError(
          field: field,
          message: message ?? 'Value cannot be empty',
        ),
      );
    }
    return ValidationSuccess<String>(value);
  }

  /// Validates that a number is within range
  static ValidationResult<T> inRange<T extends num>(
    final T value,
    final String field, {
    final T? min,
    final T? max,
    final String? message,
  }) {
    if ((min != null && value < min) || (max != null && value > max)) {
      return ValidationFailure<T>.single(
        RangeValidationError(
          field: field,
          min: min,
          max: max,
          actualValue: value,
          message: message ?? 'Value out of range',
        ),
      );
    }
    return ValidationSuccess<T>(value);
  }

  /// Validates string length
  static ValidationResult<String> lengthInRange(
    final String value,
    final String field, {
    final int? minLength,
    final int? maxLength,
    final String? message,
  }) {
    final int length = value.length;
    if ((minLength != null && length < minLength) || (maxLength != null && length > maxLength)) {
      return ValidationFailure<String>.single(
        LengthError(
          field: field,
          minLength: minLength,
          maxLength: maxLength,
          actualLength: length,
          message: message ?? 'Invalid length',
        ),
      );
    }
    return ValidationSuccess<String>(value);
  }

  /// Validates that value matches pattern
  static ValidationResult<String> matchesPattern(
    final String value,
    final String field,
    final RegExp pattern, {
    final String? message,
    final String? expectedFormat,
  }) {
    if (!pattern.hasMatch(value)) {
      return ValidationFailure<String>.single(
        FormatError(
          field: field,
          expectedFormat: expectedFormat ?? pattern.pattern,
          actualValue: value,
          message: message ?? 'Invalid format',
        ),
      );
    }
    return ValidationSuccess<String>(value);
  }

  /// Validates that value is in allowed set
  static ValidationResult<T> oneOf<T>(
    final T value,
    final String field,
    final List<T> allowedValues, {
    final String? message,
  }) {
    if (!allowedValues.contains(value)) {
      return ValidationFailure<T>.single(
        InvalidValueError(
          field: field,
          allowedValues: allowedValues,
          actualValue: value,
          message: message ?? 'Invalid value',
        ),
      );
    }
    return ValidationSuccess<T>(value);
  }

  /// Combines multiple validation results
  static ValidationResult<T> combine<T>(
    final T value,
    final List<ValidationResult<T>> results,
  ) {
    final List<ValidationError> allErrors = <ValidationError>[];
    for (final ValidationResult<T> result in results) {
      if (result is ValidationFailure<T>) {
        allErrors.addAll(result.errors);
      }
    }
    if (allErrors.isEmpty) {
      return ValidationSuccess<T>(value);
    }
    return ValidationFailure<T>(allErrors);
  }
}
