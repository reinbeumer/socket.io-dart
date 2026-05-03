/// Value object for query parameters in Socket.IO connections.
///
/// Wraps query parameters with validation and type safety.
/// Query parameters are used during socket connection and namespace operations.
///
/// Example:
/// ```dart
/// final query = QueryParameters({'token': 'abc123', 'room': 'chat'});
/// print(query.get('token')); // 'abc123'
/// print(query.getOrDefault('missing', 'default')); // 'default'
/// ```
class QueryParameters {
  final Map<String, String> _parameters;

  /// Creates a QueryParameters from a map.
  ///
  /// Validates that all values can be represented as strings.
  /// Throws [ArgumentError] if any value is null or cannot be converted to string.
  QueryParameters(final Map<String, dynamic> parameters) : _parameters = _validateAndConvert(parameters);

  /// Creates an empty QueryParameters.
  QueryParameters.empty() : _parameters = <String, String>{};

  /// Creates QueryParameters from a query string.
  ///
  /// Example: `'token=abc&room=chat'` becomes `{'token': 'abc', 'room': 'chat'}`
  factory QueryParameters.fromQueryString(final String queryString) {
    if (queryString.isEmpty) {
      return QueryParameters.empty();
    }

    final Map<String, String> params = <String, String>{};
    final String cleanQuery = queryString.startsWith('?') ? queryString.substring(1) : queryString;

    for (final String pair in cleanQuery.split('&')) {
      if (pair.isEmpty) continue;

      final List<String> parts = pair.split('=');
      if (parts.isEmpty) continue;

      final String key = Uri.decodeComponent(parts[0]);
      final String value = parts.length > 1 ? Uri.decodeComponent(parts[1]) : '';
      params[key] = value;
    }

    return QueryParameters(params);
  }

  static Map<String, String> _validateAndConvert(final Map<String, dynamic> parameters) {
    final Map<String, String> result = <String, String>{};

    for (final MapEntry<String, dynamic> entry in parameters.entries) {
      final String key = entry.key;
      final dynamic value = entry.value;

      if (value == null) {
        throw ArgumentError('Query parameter value for key "$key" cannot be null');
      }

      result[key] = value.toString();
    }

    return result;
  }

  /// Gets a parameter value by key.
  ///
  /// Returns null if the key doesn't exist.
  String? get(final String key) => _parameters[key];

  /// Gets a parameter value by key, or returns a default value.
  String getOrDefault(final String key, final String defaultValue) => _parameters[key] ?? defaultValue;

  /// Checks if a parameter exists.
  bool has(final String key) => _parameters.containsKey(key);

  /// Returns all parameter keys.
  Iterable<String> get keys => _parameters.keys;

  /// Returns all parameter values.
  Iterable<String> get values => _parameters.values;

  /// Returns all parameters as entries.
  Iterable<MapEntry<String, String>> get entries => _parameters.entries;

  /// Returns the number of parameters.
  int get length => _parameters.length;

  /// Checks if there are no parameters.
  bool get isEmpty => _parameters.isEmpty;

  /// Checks if there are any parameters.
  bool get isNotEmpty => _parameters.isNotEmpty;

  /// Converts to a Map<String, String>.
  Map<String, String> toMap() => Map<String, String>.from(_parameters);

  /// Converts to a Map<String, dynamic> for backward compatibility.
  Map<String, dynamic> toDynamicMap() => Map<String, dynamic>.from(_parameters);

  /// Converts to a query string.
  ///
  /// Example: `{'token': 'abc', 'room': 'chat'}` becomes `'token=abc&room=chat'`
  String toQueryString() {
    if (isEmpty) return '';

    return entries
        .map((final MapEntry<String, String> e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Creates a new QueryParameters with an additional parameter.
  QueryParameters withParameter(final String key, final String value) =>
      QueryParameters(<String, dynamic>{..._parameters, key: value});

  /// Creates a new QueryParameters without a specific parameter.
  QueryParameters withoutParameter(final String key) => QueryParameters(
        Map<String, String>.from(_parameters)..remove(key),
      );

  /// Merges with another QueryParameters.
  ///
  /// Parameters from [other] take precedence in case of conflicts.
  QueryParameters merge(final QueryParameters other) =>
      QueryParameters(<String, dynamic>{..._parameters, ...other._parameters});

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (other is! QueryParameters) return false;

    if (_parameters.length != other._parameters.length) return false;

    for (final MapEntry<String, String> entry in _parameters.entries) {
      if (other._parameters[entry.key] != entry.value) return false;
    }

    return true;
  }

  @override
  int get hashCode {
    int hash = 0;
    for (final MapEntry<String, String> entry in _parameters.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() => 'QueryParameters(${toQueryString()})';
}
