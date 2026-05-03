/// socket_data_models.dart
///
/// Type-safe models for socket data storage
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library socket_data_models;

/// Type-safe data store for socket-specific data.
///
/// Replaces `Map<String, dynamic> data` with proper type safety.
class SocketDataModel {
  final Map<String, Object?> _data;

  /// Creates a new empty SocketDataModel.
  SocketDataModel() : _data = <String, Object?>{};

  /// Creates from an existing map.
  SocketDataModel.fromMap(final Map<String, Object?> data) : _data = Map<String, Object?>.from(data);

  /// Gets a value by key.
  Object? operator [](final String key) => _data[key];

  /// Sets a value by key.
  void operator []=(final String key, final Object? value) {
    _data[key] = value;
  }

  /// Gets a string value, or null if not found or wrong type.
  String? getString(final String key) {
    final Object? value = _data[key];
    return value is String ? value : null;
  }

  /// Gets an int value, or null if not found or wrong type.
  int? getInt(final String key) {
    final Object? value = _data[key];
    return value is int ? value : null;
  }

  /// Gets a bool value, or null if not found or wrong type.
  bool? getBool(final String key) {
    final Object? value = _data[key];
    return value is bool ? value : null;
  }

  /// Gets a double value, or null if not found or wrong type.
  double? getDouble(final String key) {
    final Object? value = _data[key];
    return value is double ? value : null;
  }

  /// Gets a map value, or null if not found or wrong type.
  Map<String, Object?>? getMap(final String key) {
    final Object? value = _data[key];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    return null;
  }

  /// Gets a list value, or null if not found or wrong type.
  List<Object?>? getList(final String key) {
    final Object? value = _data[key];
    if (value is List<Object?>) return value;
    if (value is List) return List<Object?>.from(value);
    return null;
  }

  /// Checks if a key exists.
  bool containsKey(final String key) => _data.containsKey(key);

  /// Removes a key.
  Object? remove(final String key) => _data.remove(key);

  /// Clears all data.
  void clear() => _data.clear();

  /// Returns all keys.
  Iterable<String> get keys => _data.keys;

  /// Returns all values.
  Iterable<Object?> get values => _data.values;

  /// Returns the number of entries.
  int get length => _data.length;

  /// Checks if empty.
  bool get isEmpty => _data.isEmpty;

  /// Checks if not empty.
  bool get isNotEmpty => _data.isNotEmpty;

  /// Converts to a plain map.
  Map<String, Object?> toMap() => Map<String, Object?>.from(_data);

  /// Creates a copy.
  SocketDataModel copy() => SocketDataModel.fromMap(_data);

  @override
  String toString() => 'SocketDataModel($_data)';
}
