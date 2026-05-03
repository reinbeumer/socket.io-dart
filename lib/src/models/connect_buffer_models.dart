/// connect_buffer_models.dart
///
/// Model for managing pending namespace connection requests.
///
/// The connect buffer stores namespace names that are waiting to be connected
/// after the default namespace ('/') connection is established.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library connect_buffer_models;

import '../value_objects/namespace_name_vo.dart';

/// Model for managing pending namespace connections.
///
/// In Socket.IO, non-default namespaces cannot be connected until after
/// the default namespace ('/') is connected. The ConnectBuffer stores
/// these pending connection requests and processes them once the default
/// namespace is ready.
class ConnectBuffer {
  final List<String> _buffer;

  /// Creates an empty connect buffer.
  ConnectBuffer() : _buffer = <String>[];

  /// Creates a connect buffer from an existing list of namespace names.
  ConnectBuffer.fromList(final List<String> namespaces) : _buffer = List<String>.from(namespaces);

  /// Adds a namespace to the buffer.
  void add(final String namespace) {
    if (!_buffer.contains(namespace)) {
      _buffer.add(namespace);
    }
  }

  /// Adds a namespace using NamespaceName value object.
  void addTyped(final NamespaceName namespace) {
    add(namespace.value);
  }

  /// Removes a namespace from the buffer.
  bool remove(final String namespace) => _buffer.remove(namespace);

  /// Removes a namespace using NamespaceName value object.
  bool removeTyped(final NamespaceName namespace) => remove(namespace.value);

  /// Clears all pending connections.
  void clear() => _buffer.clear();

  /// Returns true if the buffer is empty.
  bool get isEmpty => _buffer.isEmpty;

  /// Returns true if the buffer is not empty.
  bool get isNotEmpty => _buffer.isNotEmpty;

  /// Returns the number of pending connections.
  int get length => _buffer.length;

  /// Returns true if the buffer contains the namespace.
  bool contains(final String namespace) => _buffer.contains(namespace);

  /// Returns true if the buffer contains the namespace.
  bool containsTyped(final NamespaceName namespace) => contains(namespace.value);

  /// Returns an immutable copy of the buffer contents.
  List<String> toList() => List<String>.unmodifiable(_buffer);

  /// Processes all buffered connections using the provided callback.
  ///
  /// After processing, the buffer is cleared.
  void processAll(final void Function(String namespace) processor) {
    final List<String> snapshot = List<String>.from(_buffer);
    _buffer.clear();
    snapshot.forEach(processor);
  }

  @override
  String toString() => 'ConnectBuffer(${_buffer.length} pending: ${_buffer.join(", ")})';

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ConnectBuffer && runtimeType == other.runtimeType && _listEquals(_buffer, other._buffer);

  static bool _listEquals(final List<String> a, final List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_buffer);
}
