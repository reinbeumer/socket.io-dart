/// Value object representing event arguments in Socket.IO communication.
///
/// Provides a type-safe wrapper around event arguments, supporting various data types
/// and providing safe access methods.
library event_arguments_vo;

import '../models/event_data_models.dart';

/// Represents a list of event arguments with type-safe access methods.
///
/// Event arguments can contain any JSON-serializable data including strings,
/// numbers, booleans, maps, lists, and null values.
///
/// Example:
/// ```dart
/// final EventArguments args = EventArguments(['hello', 42, {'key': 'value'}]);
/// final String? first = args.getStringAt(0);
/// final int? second = args.getIntAt(1);
/// final Map<String, dynamic>? third = args.getMapAt(2);
/// ```
class EventArguments {
  /// The underlying list of arguments.
  final List<Object?> arguments;

  /// Creates event arguments from a list of objects.
  ///
  /// Throws [ArgumentError] if [arguments] is null.
  factory EventArguments(final List<Object?> arguments) =>
      EventArguments.unchecked(List<Object?>.unmodifiable(arguments));

  /// Creates empty event arguments.
  factory EventArguments.empty() => const EventArguments.unchecked(<Object?>[]);

  /// Creates event arguments from a single value.
  factory EventArguments.single(final Object? value) => EventArguments.unchecked(<Object?>[value]);

  /// Creates event arguments from multiple values.
  factory EventArguments.multiple(final List<Object?> values) => EventArguments(values);

  /// Creates event arguments from EventData objects.
  factory EventArguments.fromEventData(final List<EventData> eventData) {
    final List<Object?> values = <Object?>[];
    for (final EventData data in eventData) {
      if (data is StringEventData) {
        values.add(data.value);
      } else if (data is NumericEventData) {
        values.add(data.value);
      } else if (data is BooleanEventData) {
        values.add(data.value);
      } else if (data is MapEventData) {
        values.add(data.value);
      } else if (data is ListEventData) {
        values.add(data.value);
      } else if (data is NullEventData) {
        values.add(null);
      } else if (data is ObjectEventData) {
        values.add(data.value);
      }
    }
    return EventArguments.unchecked(values);
  }

  /// Unchecked constructor for internal use.
  ///
  /// Does not validate or copy the input list.
  /// Use when you are certain the input is valid and immutable.
  const EventArguments.unchecked(this.arguments);

  /// The number of arguments.
  int get length => arguments.length;

  /// Whether there are no arguments.
  bool get isEmpty => arguments.isEmpty;

  /// Whether there are arguments.
  bool get isNotEmpty => arguments.isNotEmpty;

  /// Gets the argument at the specified index.
  ///
  /// Returns null if index is out of bounds.
  Object? operator [](final int index) {
    if (index < 0 || index >= arguments.length) {
      return null;
    }
    return arguments[index];
  }

  /// Gets the argument at the specified index as a String.
  ///
  /// Returns null if the index is out of bounds or the value is not a String.
  String? getStringAt(final int index) {
    final Object? value = this[index];
    return value is String ? value : null;
  }

  /// Gets the argument at the specified index as an int.
  ///
  /// Returns null if the index is out of bounds or the value is not an int.
  /// Attempts to convert num to int if needed.
  int? getIntAt(final int index) {
    final Object? value = this[index];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  /// Gets the argument at the specified index as a double.
  ///
  /// Returns null if the index is out of bounds or the value is not a number.
  double? getDoubleAt(final int index) {
    final Object? value = this[index];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  /// Gets the argument at the specified index as a bool.
  ///
  /// Returns null if the index is out of bounds or the value is not a bool.
  bool? getBoolAt(final int index) {
    final Object? value = this[index];
    return value is bool ? value : null;
  }

  /// Gets the argument at the specified index as a Map.
  ///
  /// Returns null if the index is out of bounds or the value is not a Map.
  Map<String, dynamic>? getMapAt(final int index) {
    final Object? value = this[index];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// Gets the argument at the specified index as a List.
  ///
  /// Returns null if the index is out of bounds or the value is not a List.
  List<Object?>? getListAt(final int index) {
    final Object? value = this[index];
    if (value is List<Object?>) {
      return value;
    }
    if (value is List) {
      return List<Object?>.from(value);
    }
    return null;
  }

  /// Converts the arguments to EventData objects.
  List<EventData> toEventData() {
    final List<EventData> result = <EventData>[];
    for (final Object? arg in arguments) {
      if (arg is String) {
        result.add(StringEventData(arg));
      } else if (arg is num) {
        result.add(NumericEventData(arg));
      } else if (arg is bool) {
        result.add(BooleanEventData(arg));
      } else if (arg is Map<String, dynamic>) {
        result.add(MapEventData(arg));
      } else if (arg is Map) {
        result.add(MapEventData(Map<String, dynamic>.from(arg)));
      } else if (arg is List) {
        result.add(ListEventData(arg));
      } else if (arg == null) {
        result.add(const NullEventData());
      } else {
        result.add(ObjectEventData(arg));
      }
    }
    return result;
  }

  /// Converts to a raw list.
  List<Object?> toList() => List<Object?>.from(arguments);

  /// Converts to JSON-serializable list.
  List<Object?> toJson() => toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is EventArguments && runtimeType == other.runtimeType && _listEquals(arguments, other.arguments);

  @override
  int get hashCode => Object.hashAll(arguments);

  @override
  String toString() => 'EventArguments(${arguments.length} args)';

  /// Helper to compare lists deeply.
  static bool _listEquals(final List<Object?>? a, final List<Object?>? b) {
    if (a == null) {
      return b == null;
    }
    if (b == null || a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

/// Extension methods for EventArguments.
extension EventArgumentsExtension on EventArguments {
  /// Maps each argument through a function.
  List<T> map<T>(final T Function(Object?) fn) => arguments.map(fn).toList();

  /// Filters arguments by a predicate.
  List<Object?> where(final bool Function(Object?) test) => arguments.where(test).toList();

  /// Returns the first argument, or null if empty.
  Object? get firstOrNull => isEmpty ? null : arguments.first;

  /// Returns the last argument, or null if empty.
  Object? get lastOrNull => isEmpty ? null : arguments.last;

  /// Checks if all arguments match a predicate.
  bool every(final bool Function(Object?) test) => arguments.every(test);

  /// Checks if any argument matches a predicate.
  bool any(final bool Function(Object?) test) => arguments.any(test);

  /// Takes the first n arguments.
  EventArguments take(final int count) => EventArguments.unchecked(arguments.take(count).toList());

  /// Skips the first n arguments.
  EventArguments skip(final int count) => EventArguments.unchecked(arguments.skip(count).toList());
}
