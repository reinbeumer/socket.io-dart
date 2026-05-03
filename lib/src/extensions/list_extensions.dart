/// list_extensions.dart
///
/// Extension methods for List operations to provide safe access
/// and common list manipulation patterns.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library list_extensions;

/// Extension methods for List providing safe access and operations
extension ListSafeAccess<T> on List<T> {
  /// Gets an element at index or returns null if out of bounds
  T? getOrNull(final int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Gets an element at index or returns default value if out of bounds
  T getOrDefault(final int index, final T defaultValue) => getOrNull(index) ?? defaultValue;

  /// Gets the first element or null if list is empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Gets the last element or null if list is empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Gets the first element matching predicate or null
  T? firstWhereOrNull(final bool Function(T element) test) {
    for (final T element in this) {
      if (test(element)) return element;
    }
    return null;
  }

  /// Gets the last element matching predicate or null
  T? lastWhereOrNull(final bool Function(T element) test) {
    for (int i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }

  /// Splits list into chunks of specified size
  List<List<T>> chunk(final int size) {
    if (size <= 0) throw ArgumentError('Chunk size must be positive');

    final List<List<T>> chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      final int end = (i + size < length) ? i + size : length;
      chunks.add(sublist(i, end));
    }
    return chunks;
  }

  /// Groups elements by a key
  Map<K, List<T>> groupBy<K>(final K Function(T element) keySelector) {
    final Map<K, List<T>> groups = <K, List<T>>{};
    for (final T element in this) {
      final K key = keySelector(element);
      groups.putIfAbsent(key, () => <T>[]).add(element);
    }
    return groups;
  }

  /// Removes duplicates from the list
  List<T> distinct() => toSet().toList();

  /// Removes duplicates based on a key selector
  List<T> distinctBy<K>(final K Function(T element) keySelector) {
    final Set<K> seen = <K>{};
    final List<T> result = <T>[];

    for (final T element in this) {
      final K key = keySelector(element);
      if (seen.add(key)) {
        result.add(element);
      }
    }
    return result;
  }

  /// Partitions list into two lists based on a predicate
  ({List<T> matched, List<T> unmatched}) partition(final bool Function(T element) test) {
    final List<T> matched = <T>[];
    final List<T> unmatched = <T>[];

    for (final T element in this) {
      if (test(element)) {
        matched.add(element);
      } else {
        unmatched.add(element);
      }
    }

    return (matched: matched, unmatched: unmatched);
  }

  /// Intersperses a separator between elements
  List<T> intersperse(final T separator) {
    if (isEmpty) return <T>[];
    if (length == 1) return <T>[first];

    final List<T> result = <T>[];
    for (int i = 0; i < length; i++) {
      result.add(this[i]);
      if (i < length - 1) {
        result.add(separator);
      }
    }
    return result;
  }

  /// Takes elements while predicate is true
  List<T> takeWhile(final bool Function(T element) test) {
    final List<T> result = <T>[];
    for (final T element in this) {
      if (!test(element)) break;
      result.add(element);
    }
    return result;
  }

  /// Skips elements while predicate is true
  List<T> skipWhile(final bool Function(T element) test) {
    int index = 0;
    while (index < length && test(this[index])) {
      index++;
    }
    return sublist(index);
  }

  /// Zips two lists together
  List<({T first, U second})> zip<U>(final List<U> other) {
    final int minLength = length < other.length ? length : other.length;
    final List<({T first, U second})> result = <({T first, U second})>[];

    for (int i = 0; i < minLength; i++) {
      result.add((first: this[i], second: other[i]));
    }

    return result;
  }

  /// Flattens a list of lists (only works when T is also a List)
  List<E> flatten<E>() {
    if (this is! List<List<E>>) {
      throw UnsupportedError('flatten only works on List<List<T>>');
    }

    final List<E> result = <E>[];
    for (final dynamic element in this) {
      if (element is List<E>) {
        result.addAll(element);
      }
    }
    return result;
  }

  /// Counts elements matching a predicate
  int count(final bool Function(T element) test) {
    int counter = 0;
    for (final T element in this) {
      if (test(element)) counter++;
    }
    return counter;
  }

  /// Checks if list contains any element matching predicate
  bool anyMatch(final bool Function(T element) test) => firstWhereOrNull(test) != null;

  /// Checks if all elements match predicate (returns true for empty list)
  bool allMatch(final bool Function(T element) test) {
    for (final T element in this) {
      if (!test(element)) return false;
    }
    return true;
  }

  /// Checks if no elements match predicate
  bool noneMatch(final bool Function(T element) test) => !anyMatch(test);
}

/// Extension methods for List<dynamic> with type checking
extension DynamicListTypeChecking on List<dynamic> {
  /// Checks if all elements are of a specific type
  bool allOfType<T>() => every((final dynamic element) => element is T);

  /// Filters elements of a specific type
  List<T> whereType<T>() => <T>[...where((final dynamic element) => element is T).cast<T>()];

  /// Safely casts to List<T> if all elements are of type T
  List<T>? tryCast<T>() {
    if (allOfType<T>()) {
      return List<T>.from(this);
    }
    return null;
  }
}
