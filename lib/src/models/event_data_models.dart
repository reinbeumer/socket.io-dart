/// event_data_models.dart
///
/// Class hierarchy for type-safe event data
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library event_data_models;

/// Base sealed class for event data types.
///
/// Using sealed class ensures exhaustive pattern matching and makes the set
/// of event data types closed - all subtypes are defined in this file.
/// This provides type-safe event data handling instead of using dynamic.
sealed class EventData {
  const EventData();
}

/// Event data containing a string value.
class StringEventData extends EventData {
  final String value;

  const StringEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is StringEventData && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Event data containing a numeric value.
class NumericEventData extends EventData {
  final num value;

  const NumericEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is NumericEventData && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Event data containing a boolean value.
class BooleanEventData extends EventData {
  final bool value;

  const BooleanEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is BooleanEventData && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Event data containing a map of values.
class MapEventData extends EventData {
  final Map<String, Object?> value;

  const MapEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is MapEventData && runtimeType == other.runtimeType && _mapEquals(value, other.value);

  static bool _mapEquals(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll(value.entries.map((final MapEntry<String, Object?> e) => Object.hash(e.key, e.value)));

  @override
  String toString() => value.toString();
}

/// Event data containing a list of values.
class ListEventData extends EventData {
  final List<Object?> value;

  const ListEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ListEventData && runtimeType == other.runtimeType && _listEquals(value, other.value);

  static bool _listEquals(final List<Object?> a, final List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(value);

  @override
  String toString() => value.toString();
}

/// Event data representing null/no data.
class NullEventData extends EventData {
  const NullEventData();

  @override
  bool operator ==(final Object other) => identical(this, other) || other is NullEventData;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'null';
}

/// Event data containing a generic object (fallback).
class ObjectEventData extends EventData {
  final Object value;

  const ObjectEventData(this.value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is ObjectEventData && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// Utility to convert dynamic values to EventData.
extension EventDataConversion on Object? {
  EventData toEventData() {
    final Object? self = this;
    if (self == null) return const NullEventData();
    if (self is String) return StringEventData(self);
    if (self is num) return NumericEventData(self);
    if (self is bool) return BooleanEventData(self);
    if (self is Map<String, Object?>) return MapEventData(self);
    if (self is Map) return MapEventData(Map<String, Object?>.from(self));
    if (self is List<Object?>) return ListEventData(self);
    if (self is List) return ListEventData(List<Object?>.from(self));
    return ObjectEventData(self);
  }
}
