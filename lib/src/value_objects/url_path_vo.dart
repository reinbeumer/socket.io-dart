/// url_path_vo.dart
///
/// Value object for URL path with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library url_path_vo;

/// Value object representing a validated URL path.
///
/// URL paths must start with '/' and contain valid characters.
class UrlPath {
  final String value;

  const UrlPath._(this.value);

  /// Creates a UrlPath from a string with validation.
  ///
  /// Throws [ArgumentError] if the path is invalid.
  factory UrlPath(final String path) {
    if (path.isEmpty) {
      throw ArgumentError('URL path cannot be empty');
    }
    if (!path.startsWith('/')) {
      throw ArgumentError('URL path must start with "/"');
    }
    return UrlPath._(path);
  }

  /// Creates a UrlPath without validation (use with caution).
  const UrlPath.unchecked(this.value);

  /// Default Socket.IO path.
  static const UrlPath defaultSocketIO = UrlPath.unchecked('/socket.io');

  /// Root path.
  static const UrlPath root = UrlPath.unchecked('/');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is UrlPath && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
