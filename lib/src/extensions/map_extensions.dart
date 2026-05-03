/// map_extensions.dart
///
/// Extension methods for Map operations to provide type-safe getters
/// and common map manipulation patterns.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library map_extensions;

/// Extension methods for Map<String, dynamic> providing type-safe getters
extension MapTypeSafeGetters on Map<String, dynamic> {
  /// Gets a String value or returns null if not found or wrong type
  String? getStringOrNull(final String key) {
    final dynamic value = this[key];
    return value is String ? value : null;
  }

  /// Gets a String value or returns default if not found or wrong type
  String getString(final String key, final String defaultValue) => getStringOrNull(key) ?? defaultValue;

  /// Gets an int value or returns null if not found or wrong type
  int? getIntOrNull(final String key) {
    final dynamic value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  /// Gets an int value or returns default if not found or wrong type
  int getInt(final String key, final int defaultValue) => getIntOrNull(key) ?? defaultValue;

  /// Gets a double value or returns null if not found or wrong type
  double? getDoubleOrNull(final String key) {
    final dynamic value = this[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }

  /// Gets a double value or returns default if not found or wrong type
  double getDouble(final String key, final double defaultValue) => getDoubleOrNull(key) ?? defaultValue;

  /// Gets a bool value or returns null if not found or wrong type
  bool? getBoolOrNull(final String key) {
    final dynamic value = this[key];
    return value is bool ? value : null;
  }

  /// Gets a bool value or returns default if not found or wrong type
  bool getBool(final String key, final bool defaultValue) => getBoolOrNull(key) ?? defaultValue;

  /// Gets a List value or returns null if not found or wrong type
  List<T>? getListOrNull<T>(final String key) {
    final dynamic value = this[key];
    if (value is List<T>) return value;
    if (value is List) {
      try {
        return List<T>.from(value);
      } on Object {
        return null;
      }
    }
    return null;
  }

  /// Gets a List value or returns default if not found or wrong type
  List<T> getList<T>(final String key, final List<T> defaultValue) => getListOrNull<T>(key) ?? defaultValue;

  /// Gets a Map value or returns null if not found or wrong type
  Map<K, V>? getMapOrNull<K, V>(final String key) {
    final dynamic value = this[key];
    if (value is Map<K, V>) return value;
    if (value is Map) {
      try {
        return Map<K, V>.from(value);
      } on Object {
        return null;
      }
    }
    return null;
  }

  /// Gets a Map value or returns default if not found or wrong type
  Map<K, V> getMap<K, V>(final String key, final Map<K, V> defaultValue) => getMapOrNull<K, V>(key) ?? defaultValue;

  /// Gets a nested value using a path (e.g., 'user.profile.name')
  dynamic getNestedValue(final String path, [final dynamic defaultValue]) {
    final List<String> keys = path.split('.');
    dynamic current = this;

    for (final String key in keys) {
      if (current is Map<String, dynamic>) {
        current = current[key];
        if (current == null) return defaultValue;
      } else {
        return defaultValue;
      }
    }

    return current ?? defaultValue;
  }

  /// Gets a nested String value using a path
  String? getNestedString(final String path) {
    final dynamic value = getNestedValue(path);
    return value is String ? value : null;
  }

  /// Gets a nested int value using a path
  int? getNestedInt(final String path) {
    final dynamic value = getNestedValue(path);
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

/// Extension methods for general Map operations
extension MapOperations<K, V> on Map<K, V> {
  /// Creates a new map with only the specified keys
  Map<K, V> pick(final List<K> keys) => Map<K, V>.fromEntries(
        keys.where(containsKey).map((final K key) => MapEntry<K, V>(key, this[key] as V)),
      );

  /// Creates a new map excluding the specified keys
  Map<K, V> omit(final List<K> keys) => Map<K, V>.fromEntries(
        entries.where((final MapEntry<K, V> entry) => !keys.contains(entry.key)),
      );

  /// Merges another map into this one, with the other map's values taking precedence
  Map<K, V> merge(final Map<K, V> other) => <K, V>{...this, ...other};

  /// Deep merges another map (only works with nested Map<String, dynamic>)
  Map<String, dynamic> deepMerge(final Map<String, dynamic> other) {
    if (this is! Map<String, dynamic>) {
      throw UnsupportedError('deepMerge only works with Map<String, dynamic>');
    }

    final Map<String, dynamic> result = Map<String, dynamic>.from(this as Map<String, dynamic>);

    other.forEach((final String key, final dynamic value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = (result[key] as Map<String, dynamic>).deepMerge(value);
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  /// Returns a new map with null values removed
  Map<K, V> compact() => Map<K, V>.fromEntries(
        entries.where((final MapEntry<K, V> entry) => entry.value != null),
      );

  /// Transforms values in the map
  Map<K, R> mapValues<R>(final R Function(V value) transform) =>
      map((final K key, final V value) => MapEntry<K, R>(key, transform(value)));

  /// Transforms keys in the map
  Map<R, V> mapKeys<R>(final R Function(K key) transform) =>
      map((final K key, final V value) => MapEntry<R, V>(transform(key), value));

  /// Filters entries in the map
  Map<K, V> filterEntries(final bool Function(K key, V value) predicate) => Map<K, V>.fromEntries(
        entries.where((final MapEntry<K, V> entry) => predicate(entry.key, entry.value)),
      );
}
