/// string_extensions.dart
///
/// Extension methods for String operations including validation
/// for namespace, URL paths, and query strings.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library string_extensions;

/// Extension methods for String validation and manipulation
extension StringValidation on String {
  /// Checks if string is a valid namespace name (starts with /)
  bool get isValidNamespace {
    if (isEmpty) return false;
    if (!startsWith('/')) return false;
    // Check for invalid characters
    final RegExp invalidChars = RegExp('[^a-zA-Z0-9/_-]');
    return !invalidChars.hasMatch(this);
  }

  /// Checks if string is a valid URL path (starts with /)
  bool get isValidUrlPath {
    if (isEmpty) return false;
    return startsWith('/');
  }

  /// Checks if string is a valid room name (non-empty, no special chars)
  bool get isValidRoomName {
    if (isEmpty) return false;
    // Allow alphanumeric, underscore, hyphen, and dot
    final RegExp validPattern = RegExp(r'^[a-zA-Z0-9_.-]+$');
    return validPattern.hasMatch(this);
  }

  /// Checks if string is a valid event name (non-empty, not reserved)
  bool get isValidEventName {
    if (isEmpty) return false;

    // Reserved Socket.IO event names
    const List<String> reserved = <String>[
      'connect',
      'connect_error',
      'disconnect',
      'disconnecting',
      'newListener',
      'removeListener',
      'error',
    ];

    return !reserved.contains(this);
  }

  /// Checks if string is a valid connection ID (non-empty)
  bool get isValidConnectionId => isNotEmpty && length >= 3;

  /// Checks if string is a valid packet ID (non-empty, alphanumeric)
  bool get isValidPacketId {
    if (isEmpty) return false;
    final RegExp validPattern = RegExp(r'^[a-zA-Z0-9-_]+$');
    return validPattern.hasMatch(this);
  }
}

/// Extension methods for String parsing
extension StringParsing on String {
  /// Parses query string into Map<String, String>
  Map<String, String> parseQueryString() {
    if (isEmpty) return <String, String>{};

    final String query = startsWith('?') ? substring(1) : this;
    if (query.isEmpty) return <String, String>{};

    final Map<String, String> result = <String, String>{};

    for (final String pair in query.split('&')) {
      final List<String> parts = pair.split('=');
      if (parts.isEmpty) continue;

      final String key = Uri.decodeComponent(parts[0]);
      final String value = parts.length > 1 ? Uri.decodeComponent(parts[1]) : '';

      result[key] = value;
    }

    return result;
  }

  /// Parses namespace with optional query parameters
  /// Returns (namespace, queryParams)
  ({String namespace, Map<String, String> queryParams}) parseNamespaceWithQuery() {
    final Uri uri = Uri.parse(this);
    return (
      namespace: uri.path.isEmpty ? '/' : uri.path,
      queryParams: uri.queryParameters,
    );
  }

  /// Converts string to camelCase
  String toCamelCase() {
    if (isEmpty) return this;

    final List<String> words = split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return this;

    final StringBuffer buffer = StringBuffer(words[0].toLowerCase());
    for (int i = 1; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        buffer.write(words[i][0].toUpperCase());
        if (words[i].length > 1) {
          buffer.write(words[i].substring(1).toLowerCase());
        }
      }
    }

    return buffer.toString();
  }

  /// Converts string to snake_case
  String toSnakeCase() {
    if (isEmpty) return this;

    final RegExp upperCase = RegExp('[A-Z]');
    return replaceAllMapped(upperCase, (final Match match) {
      final String char = match.group(0)!;
      return match.start == 0 ? char.toLowerCase() : '_${char.toLowerCase()}';
    });
  }

  /// Converts string to kebab-case
  String toKebabCase() => toSnakeCase().replaceAll('_', '-');

  /// Truncates string to max length with ellipsis
  String truncate(final int maxLength, {final String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Capitalizes first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Removes all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Checks if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Checks if string is null, empty, or only whitespace
  bool get isNullOrBlank => trim().isEmpty;
}

/// Extension methods for nullable String
extension NullableStringExtensions on String? {
  /// Returns true if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if string is null, empty, or only whitespace
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// Returns the string or a default value if null or empty
  String orDefault(final String defaultValue) => isNullOrEmpty ? defaultValue : this!;

  /// Returns the string or a default value if null or blank
  String orDefaultIfBlank(final String defaultValue) => isNullOrBlank ? defaultValue : this!;
}

/// Extension methods for String matching and comparison
extension StringMatching on String {
  /// Checks if string matches a pattern
  bool matches(final RegExp pattern) => pattern.hasMatch(this);

  /// Checks if string contains another string (case insensitive)
  bool containsIgnoreCase(final String other) => toLowerCase().contains(other.toLowerCase());

  /// Checks if string equals another string (case insensitive)
  bool equalsIgnoreCase(final String other) => toLowerCase() == other.toLowerCase();

  /// Checks if string starts with prefix (case insensitive)
  bool startsWithIgnoreCase(final String prefix) => toLowerCase().startsWith(prefix.toLowerCase());

  /// Checks if string ends with suffix (case insensitive)
  bool endsWithIgnoreCase(final String suffix) => toLowerCase().endsWith(suffix.toLowerCase());
}

/// Extension methods for String encoding/escaping
extension StringEncoding on String {
  /// URL encodes the string
  String urlEncode() => Uri.encodeComponent(this);

  /// URL decodes the string
  String urlDecode() => Uri.decodeComponent(this);

  /// Escapes special characters for use in JSON
  String escapeJson() => replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
