import 'dart:convert';
import 'dart:io';

import 'package:socket_io/socket_io.dart' as sio;
import 'package:socket_io_common/socket_io_common.dart' show SEPARATOR;
import 'package:test/test.dart';

void main() {
  group('Polling transport integration', () {
    late HttpClient client;
    late sio.Server server;
    late Uri baseUri;

    setUp(() async {
      client = HttpClient();
      server = sio.Server();

      server.onConnection((final sio.Socket socket) {
        socket.on('msg', (final sio.SocketIOEventData data) {
          socket.emit('fromServer', 'Message received: $data');
        });
      });

      await server.listen(0);
      baseUri = Uri(
        scheme: 'http',
        host: '127.0.0.1',
        port: server.port!,
        path: '/socket.io/',
      );
    });

    tearDown(() async {
      client.close(force: true);
      await server.close();
    });

    test('decodes record-separator-delimited Engine.IO v4 payloads', () async {
      final String sid = await _openPollingSession(client, baseUri);

      final HttpClientResponse connectResponse = await _postPollingPayload(client, baseUri, sid, '40');
      expect(connectResponse.statusCode, equals(HttpStatus.ok));
      await connectResponse.drain<void>();

      final HttpClientResponse eventResponse = await _postPollingPayload(
        client,
        baseUri,
        sid,
        '42["msg","first"]${SEPARATOR}42["msg","second"]',
      );
      expect(eventResponse.statusCode, equals(HttpStatus.ok));
      await eventResponse.drain<void>();

      final String pollData = await _pollForMessages(client, baseUri, sid);
      expect(pollData, contains('Message received: first'));
      expect(pollData, contains('Message received: second'));
    });

    test('decodes concatenated polling payloads as a compatibility fallback', () async {
      final String sid = await _openPollingSession(client, baseUri);

      final HttpClientResponse connectResponse = await _postPollingPayload(client, baseUri, sid, '40');
      expect(connectResponse.statusCode, equals(HttpStatus.ok));
      await connectResponse.drain<void>();

      final HttpClientResponse eventResponse = await _postPollingPayload(
        client,
        baseUri,
        sid,
        '42["msg","first"]42["msg","second"]',
      );
      expect(eventResponse.statusCode, equals(HttpStatus.ok));
      await eventResponse.drain<void>();

      final String pollData = await _pollForMessages(client, baseUri, sid);
      expect(pollData, contains('Message received: first'));
      expect(pollData, contains('Message received: second'));
    });

    test('answers polling CORS preflight requests', () async {
      final HttpClientRequest request = await client.openUrl(
        'OPTIONS',
        _pollingUri(baseUri),
      );
      request.headers
        ..add('origin', 'https://example.com')
        ..add('Access-Control-Request-Method', 'POST')
        ..add('Access-Control-Request-Headers', 'Content-Type');

      final HttpClientResponse response = await request.close();
      final String body = await utf8.decoder.bind(response).join();

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(body, isEmpty);
      expect(
        response.headers.value('Access-Control-Allow-Origin'),
        equals('https://example.com'),
      );
      expect(
        response.headers.value('Access-Control-Allow-Credentials'),
        equals('true'),
      );
      expect(
        response.headers.value('Access-Control-Allow-Methods'),
        contains('OPTIONS'),
      );
      expect(
        response.headers.value('Access-Control-Allow-Headers'),
        contains('Content-Type'),
      );
      expect(
        response.headers.value(HttpHeaders.cacheControlHeader),
        contains('no-cache'),
      );
    });
  });
}

Future<String> _openPollingSession(
  final HttpClient client,
  final Uri baseUri,
) async {
  final HttpClientRequest request = await client.getUrl(_pollingUri(baseUri));
  final HttpClientResponse response = await request.close();
  final String body = await utf8.decoder.bind(response).join();

  expect(response.statusCode, equals(HttpStatus.ok));

  final Match? sidMatch = RegExp(r'"sid":"([^"]+)"').firstMatch(body);
  expect(sidMatch, isNotNull, reason: 'Missing sid in handshake: $body');

  return sidMatch!.group(1)!;
}

Future<HttpClientResponse> _postPollingPayload(
  final HttpClient client,
  final Uri baseUri,
  final String sid,
  final String payload,
) async {
  final HttpClientRequest request = await client.postUrl(_pollingUri(baseUri, sid: sid));
  request.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
  request.write(payload);
  return request.close();
}

Future<String> _pollForMessages(
  final HttpClient client,
  final Uri baseUri,
  final String sid,
) async {
  final HttpClientRequest request = await client.getUrl(_pollingUri(baseUri, sid: sid));
  final HttpClientResponse response = await request.close();
  final String body = await utf8.decoder.bind(response).join();

  expect(response.statusCode, equals(HttpStatus.ok));
  return body;
}

Uri _pollingUri(
  final Uri baseUri, {
  final String? sid,
}) {
  return baseUri.replace(queryParameters: <String, String>{
    'EIO': '4',
    'transport': 'polling',
    't': DateTime.now().microsecondsSinceEpoch.toString(),
    if (sid != null) 'sid': sid,
  });
}
