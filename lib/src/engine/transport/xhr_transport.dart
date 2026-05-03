// xhr_transport.dart
//
// Purpose:
//
// Description:
//
// History:
//    22/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';
import 'dart:io';

import '../../types/common_types.dart' show Headers;
import '../connect.dart';
import 'polling_transport.dart';

class XHRTransport extends PollingTransport {
  XHRTransport(super.connect);

  /// Overrides `onRequest` to handle `OPTIONS`..
  ///
  /// @param {http.IncomingMessage}
  /// @api private
  @override
  Future<void> onRequest(final SocketConnect connect) async {
    final HttpRequest req = connect.request;
    if ('OPTIONS' == req.method) {
      final HttpResponse res = req.response;
      final Headers headers = this.headers(connect);
      headers['Access-Control-Allow-Headers'] = 'Content-Type';
      headers.forEach((final String key, final Object value) {
        res.headers.set(key, value);
      });
      res
        ..statusCode = 200
        ..write('');
      await res.close();
      await connect.close();
    } else {
      await super.onRequest(connect);
    }
  }

  /// Returns headers for a response.
  ///
  /// @param {http.IncomingMessage} request
  /// @param {Object} extra headers
  /// @api private
  @override
  Headers headers(final SocketConnect connect, [Headers? extraHeaders]) {
    final HttpRequest req = connect.request;
    final Headers responseHeaders = extraHeaders ?? <String, Object>{};

    // Add CORS headers for cross-origin requests
    final String? origin = req.headers.value('origin');
    if (origin != null) {
      responseHeaders['Access-Control-Allow-Origin'] = origin;
      responseHeaders['Access-Control-Allow-Credentials'] = 'true';
    } else {
      responseHeaders['Access-Control-Allow-Origin'] = '*';
    }

    responseHeaders['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
    responseHeaders['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With';
    responseHeaders['Access-Control-Max-Age'] = '86400';

    // prevent XSS warnings on IE
    // https://github.com/LearnBoost/socket.io/pull/1333
    final String? ua = req.headers.value('user-agent');
    if (ua != null && (ua.contains(';MSIE') || ua.contains('Trident/'))) {
      responseHeaders['X-XSS-Protection'] = '0';
    }

    // Add cache control headers to prevent caching of polling responses
    responseHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
    responseHeaders['Pragma'] = 'no-cache';
    responseHeaders['Expires'] = '0';

    emit('headers', responseHeaders);
    return responseHeaders;
  }
}
