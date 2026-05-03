/// handshake_data_models.dart
///
/// Type-safe models for Socket.IO handshake data
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library handshake_data_models;

import 'dart:io';

/// Model representing Socket.IO handshake data.
///
/// Contains connection information established during the handshake process.
class HandshakeDataModel {
  /// HTTP headers from the handshake request.
  final HttpHeaders headers;

  /// Timestamp when the handshake was created.
  final DateTime time;

  /// Remote address of the client.
  final InternetAddress address;

  /// Whether the connection is cross-domain.
  final bool xdomain;

  /// Whether the connection is secure (HTTPS/WSS).
  final bool secure;

  /// Timestamp in milliseconds when the handshake was issued.
  final int issued;

  /// URL path of the connection.
  final String url;

  /// Query parameters from the connection.
  final Map<String, String> query;

  /// Additional authentication data (if any).
  final Map<String, Object?>? auth;

  const HandshakeDataModel({
    required this.headers,
    required this.time,
    required this.address,
    required this.xdomain,
    required this.secure,
    required this.issued,
    required this.url,
    required this.query,
    this.auth,
  });

  /// Creates a HandshakeDataModel from a legacy Map<String, dynamic>.
  factory HandshakeDataModel.fromMap(final Map<String, dynamic> map) => HandshakeDataModel(
        headers: map['headers'] as HttpHeaders,
        time: map['time'] is String ? DateTime.parse(map['time'] as String) : map['time'] as DateTime,
        address: map['address'] as InternetAddress,
        xdomain: map['xdomain'] as bool? ?? false,
        secure: map['secure'] as bool? ?? false,
        issued: map['issued'] as int,
        url: map['url'] as String,
        query: Map<String, String>.from((map['query'] as Map<dynamic, dynamic>?) ?? <String, String>{}),
        auth: map['auth'] as Map<String, Object?>?,
      );

  /// Converts to a Map for backward compatibility.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'headers': headers,
        'time': time.toString(),
        'address': address,
        'xdomain': xdomain,
        'secure': secure,
        'issued': issued,
        'url': url,
        'query': query,
        if (auth != null) 'auth': auth,
      };

  /// Creates a copy with optional field updates.
  HandshakeDataModel copyWith({
    final HttpHeaders? headers,
    final DateTime? time,
    final InternetAddress? address,
    final bool? xdomain,
    final bool? secure,
    final int? issued,
    final String? url,
    final Map<String, String>? query,
    final Map<String, Object?>? auth,
  }) =>
      HandshakeDataModel(
        headers: headers ?? this.headers,
        time: time ?? this.time,
        address: address ?? this.address,
        xdomain: xdomain ?? this.xdomain,
        secure: secure ?? this.secure,
        issued: issued ?? this.issued,
        url: url ?? this.url,
        query: query ?? this.query,
        auth: auth ?? this.auth,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HandshakeDataModel &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          address == other.address &&
          xdomain == other.xdomain &&
          secure == other.secure &&
          issued == other.issued &&
          url == other.url &&
          _mapEquals(query, other.query);

  static bool _mapEquals(final Map<String, String> a, final Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, String> entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        time,
        address,
        xdomain,
        secure,
        issued,
        url,
        Object.hashAll(query.entries.map((final MapEntry<String, String> e) => Object.hash(e.key, e.value))),
      );

  @override
  String toString() => 'HandshakeDataModel('
      'time: $time, '
      'address: $address, '
      'xdomain: $xdomain, '
      'secure: $secure, '
      'issued: $issued, '
      'url: $url, '
      'query: $query'
      ')';
}

/// Builder for constructing HandshakeDataModel instances.
class HandshakeDataBuilder {
  HttpHeaders? _headers;
  DateTime? _time;
  InternetAddress? _address;
  bool _xdomain = false;
  bool _secure = false;
  int? _issued;
  String? _url;
  final Map<String, String> _query = <String, String>{};
  Map<String, Object?>? _auth;

  HandshakeDataBuilder();

  HandshakeDataBuilder headers(final HttpHeaders headers) {
    _headers = headers;
    return this;
  }

  HandshakeDataBuilder time(final DateTime time) {
    _time = time;
    return this;
  }

  HandshakeDataBuilder address(final InternetAddress address) {
    _address = address;
    return this;
  }

  HandshakeDataBuilder xdomain(final bool xdomain) {
    _xdomain = xdomain;
    return this;
  }

  HandshakeDataBuilder secure(final bool secure) {
    _secure = secure;
    return this;
  }

  HandshakeDataBuilder issued(final int issued) {
    _issued = issued;
    return this;
  }

  HandshakeDataBuilder url(final String url) {
    _url = url;
    return this;
  }

  HandshakeDataBuilder addQuery(final String key, final String value) {
    _query[key] = value;
    return this;
  }

  HandshakeDataBuilder queryMap(final Map<String, String> query) {
    _query.addAll(query);
    return this;
  }

  HandshakeDataBuilder auth(final Map<String, Object?>? auth) {
    _auth = auth;
    return this;
  }

  HandshakeDataModel build() {
    if (_headers == null) throw StateError('headers is required');
    if (_time == null) throw StateError('time is required');
    if (_address == null) throw StateError('address is required');
    if (_issued == null) throw StateError('issued is required');
    if (_url == null) throw StateError('url is required');

    return HandshakeDataModel(
      headers: _headers!,
      time: _time!,
      address: _address!,
      xdomain: _xdomain,
      secure: _secure,
      issued: _issued!,
      url: _url!,
      query: Map<String, String>.from(_query),
      auth: _auth,
    );
  }
}
