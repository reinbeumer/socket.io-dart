/// namespace_name_vo.dart
///
/// Value object for namespace name with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library namespace_name_vo;

/// Value object representing a validated namespace name.
///
/// Namespace names must start with '/' and contain valid characters.
class NamespaceName {
  final String value;

  const NamespaceName._(this.value);

  /// Creates a NamespaceName from a string with validation.
  ///
  /// Throws [ArgumentError] if the namespace name is invalid.
  factory NamespaceName(final String name) {
    if (name.isEmpty) {
      throw ArgumentError('Namespace name cannot be empty');
    }
    if (!name.startsWith('/')) {
      throw ArgumentError('Namespace name must start with "/"');
    }
    // Check for invalid characters
    if (name.contains(RegExp(r'[^\w\-/.~]'))) {
      throw ArgumentError('Namespace name contains invalid characters');
    }
    return NamespaceName._(name);
  }

  /// Creates a NamespaceName without validation (use with caution).
  const NamespaceName.unchecked(this.value);

  /// Returns the default namespace "/".
  static const NamespaceName defaultNamespace = NamespaceName.unchecked('/');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is NamespaceName && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
