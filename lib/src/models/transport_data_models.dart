/// transport_data_models.dart
///
/// Type-safe models for transport layer data to replace Object/dynamic usage
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library transport_data_models;

/// Base sealed class for all transport data types
///
/// Using sealed class ensures exhaustive pattern matching and makes the set
/// of transport data types closed - all subtypes are defined in this file.
/// This replaces the generic Object type used for transport data,
/// providing type safety through inheritance.
sealed class TransportData {
  /// Converts the transport data to its raw form for transmission
  Object toRaw();
}

/// String-based transport data (most common for text protocols)
class StringTransportData extends TransportData {
  final String value;

  StringTransportData(this.value);

  @override
  String toRaw() => value;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is StringTransportData && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'StringTransportData($value)';
}

/// Binary transport data (for binary protocols or mixed content)
class BinaryTransportData extends TransportData {
  final List<int> bytes;

  BinaryTransportData(this.bytes);

  /// Creates from a list that may contain mixed types
  factory BinaryTransportData.fromList(final List<dynamic> data) {
    final List<int> bytes = <int>[];
    for (final dynamic item in data) {
      if (item is int) {
        bytes.add(item);
      } else if (item is List<int>) {
        bytes.addAll(item);
      }
    }
    return BinaryTransportData(bytes);
  }

  @override
  List<int> toRaw() => List<int>.unmodifiable(bytes);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BinaryTransportData && bytes.length == other.bytes.length && _listEquals(bytes, other.bytes);

  static bool _listEquals(final List<int> a, final List<int> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bytes);

  @override
  String toString() => 'BinaryTransportData(${bytes.length} bytes)';
}

/// JSON-encoded transport data (for structured data)
class JsonTransportData extends TransportData {
  final Map<String, dynamic> data;

  JsonTransportData(this.data);

  @override
  Map<String, dynamic> toRaw() => Map<String, dynamic>.unmodifiable(data);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is JsonTransportData && _mapEquals(data, other.data);

  static bool _mapEquals(final Map<String, dynamic> a, final Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final String key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(data.entries);

  @override
  String toString() => 'JsonTransportData($data)';
}

/// List-based transport data (for arrays or multiple payloads)
class ListTransportData extends TransportData {
  final List<Object?> items;

  ListTransportData(this.items);

  @override
  List<Object?> toRaw() => List<Object?>.unmodifiable(items);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ListTransportData && items.length == other.items.length && _listEquals(items, other.items);

  static bool _listEquals(final List<Object?> a, final List<Object?> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'ListTransportData($items)';
}

/// Mixed transport data (when data type is ambiguous or mixed)
class MixedTransportData extends TransportData {
  final Object value;

  MixedTransportData(this.value);

  @override
  Object toRaw() => value;

  @override
  bool operator ==(final Object other) => identical(this, other) || other is MixedTransportData && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MixedTransportData($value)';
}

/// Extension to convert Object to TransportData
extension ObjectToTransportData on Object {
  /// Converts a generic Object to the appropriate TransportData type
  TransportData toTransportData() {
    final Object self = this;
    if (self is String) {
      return StringTransportData(self);
    } else if (self is List<int>) {
      return BinaryTransportData(self);
    } else if (self is Map<String, dynamic>) {
      return JsonTransportData(self);
    } else if (self is List<Object?>) {
      return ListTransportData(self);
    } else {
      return MixedTransportData(self);
    }
  }
}

/// Extension to convert TransportData back to Object for legacy code
extension TransportDataToObject on TransportData {
  /// Converts TransportData to Object for compatibility with untyped APIs
  Object toObject() => toRaw();
}
