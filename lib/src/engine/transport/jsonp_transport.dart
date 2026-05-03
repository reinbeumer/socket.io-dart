// jsonp_transport.dart
//
// Purpose:
//
// Description:
//
// History:
//    22/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:convert';

import '../connect.dart';
import 'polling_transport.dart';

class JSONPTransport extends PollingTransport {
  late String head;
  late String foot;
  JSONPTransport(final SocketConnect connect) : super(connect) {
    head = '___eio[${(connect.request.uri.queryParameters['j'] ?? '').replaceAll(RegExp('[^0-9]'), '')}](';
    foot = ');';
  }

  /// Handles incoming data.
  /// Due to a bug in \n handling by browsers, we expect a escaped string.
  ///
  /// @api private
  @override
  void onData(final dynamic data) {
    // we leverage the qs module so that we get built-in DoS protection
    // and the fast alternative to decodeURIComponent
    final String d = parse(data as String)['d'] ?? '';
    // client will send already escaped newlines as \\n and newlines as \n
    // \n must be replaced with \n and \\n with \n
    final String normalized = d.replaceAllMapped(RegExp(r'(\\)?\\n'), (final Match match) {
      final String? slashes = match.group(1);
      return slashes != null ? match.group(0)! : '\n';
    });
    super.onData(normalized.replaceAll(RegExp(r'\\\\n'), '\\n'));
  }

  /// Performs the write.
  ///
  /// @api private
  @override
  Future<void> doWrite(dynamic data, final Map<String, bool>? options, [final Function? callback]) async {
    // we must output valid javascript, not valid json
    // see: http://timelessrepo.com/json-isnt-a-javascript-subset
    final String js =
        json.encode(data).replaceAll(RegExp(r'\u2028'), '\\u2028').replaceAll(RegExp(r'\u2029'), '\\u2029');

    // prepare response
    final String payload = head + js + foot;

    await super.doWrite(payload, options, callback);
  }

  static Map<String, String> parse(String query) {
    final RegExp search = RegExp('([^&=]+)=?([^&]*)');
    final Map<String, String> result = <String, String>{};
    final String normalizedQuery = query.startsWith('?') ? query.substring(1) : query;

    // Get rid off the beginning ? in query strings.
    // A custom decoder.
    String decode(final String s) => Uri.decodeComponent(s.replaceAll('+', ' '));

    // Go through all the matches and build the result map.
    for (final Match match in search.allMatches(normalizedQuery)) {
      result[decode(match.group(1)!)] = decode(match.group(2)!);
    }

    return result;
  }
}
