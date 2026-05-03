import 'dart:io';
import 'package:test/test.dart';
import 'package:socket_io/src/models/handshake_data_models.dart';

// Mock HttpHeaders for testing
class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = <String, List<String>>{};

  @override
  List<String>? operator [](final String name) => _headers[name.toLowerCase()];

  @override
  void add(final String name, final Object value, {final bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => <String>[]).add(value.toString());
  }

  @override
  void set(final String name, final Object value, {final bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = <String>[value.toString()];
  }

  @override
  void remove(final String name, final Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(final String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void forEach(final void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(final String name) {}

  @override
  void clear() => _headers.clear();

  @override
  String? value(final String name) {
    final List<String>? values = _headers[name.toLowerCase()];
    return values?.isNotEmpty ?? false ? values!.first : null;
  }

  @override
  bool get chunkedTransferEncoding => false;

  @override
  set chunkedTransferEncoding(final bool value) {}

  @override
  int get contentLength => -1;

  @override
  set contentLength(final int value) {}

  @override
  ContentType? get contentType => null;

  @override
  set contentType(final ContentType? value) {}

  @override
  DateTime? get date => null;

  @override
  set date(final DateTime? value) {}

  @override
  DateTime? get expires => null;

  @override
  set expires(final DateTime? value) {}

  @override
  String? get host => null;

  @override
  set host(final String? value) {}

  @override
  DateTime? get ifModifiedSince => null;

  @override
  set ifModifiedSince(final DateTime? value) {}

  @override
  bool get persistentConnection => true;

  @override
  set persistentConnection(final bool value) {}

  @override
  int? get port => null;

  @override
  set port(final int? value) {}
}

void main() {
  group('HandshakeDataModel', () {
    late HttpHeaders mockHeaders;
    late DateTime testTime;
    late InternetAddress testAddress;

    setUp(() {
      mockHeaders = MockHttpHeaders();
      testTime = DateTime(2024, 1, 1, 12, 0, 0);
      testAddress = InternetAddress('127.0.0.1');
    });

    test('creates with all required fields', () {
      final HandshakeDataModel handshake = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: true,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{'token': 'abc'},
      );

      expect(handshake.time, equals(testTime));
      expect(handshake.address, equals(testAddress));
      expect(handshake.xdomain, isTrue);
      expect(handshake.secure, isFalse);
      expect(handshake.issued, equals(1234567890));
      expect(handshake.url, equals('/socket.io/'));
      expect(handshake.query, equals(<String, String>{'token': 'abc'}));
    });

    test('includes optional auth field', () {
      final HandshakeDataModel handshake = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: false,
        secure: true,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{},
        auth: <String, Object?>{'userId': 123},
      );

      expect(handshake.auth, equals(<String, Object?>{'userId': 123}));
    });

    test('toMap converts to Map<String, dynamic>', () {
      final HandshakeDataModel handshake = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: true,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{'token': 'abc'},
      );

      final Map<String, dynamic> map = handshake.toMap();
      expect(map['time'], equals(testTime.toString()));
      expect(map['xdomain'], isTrue);
      expect(map['secure'], isFalse);
      expect(map['issued'], equals(1234567890));
      expect(map['url'], equals('/socket.io/'));
      expect(map['query'], equals(<String, String>{'token': 'abc'}));
    });

    test('fromMap creates from Map<String, dynamic>', () {
      final Map<String, dynamic> map = <String, dynamic>{
        'headers': mockHeaders,
        'time': testTime.toString(),
        'address': testAddress,
        'xdomain': true,
        'secure': false,
        'issued': 1234567890,
        'url': '/socket.io/',
        'query': <String, String>{'token': 'abc'},
      };

      final HandshakeDataModel handshake = HandshakeDataModel.fromMap(map);
      expect(handshake.time, equals(testTime));
      expect(handshake.xdomain, isTrue);
      expect(handshake.url, equals('/socket.io/'));
    });

    test('copyWith creates modified copy', () {
      final HandshakeDataModel original = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: false,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{},
      );

      final HandshakeDataModel modified = original.copyWith(
        xdomain: true,
        url: '/new-url/',
      );

      expect(modified.xdomain, isTrue);
      expect(modified.url, equals('/new-url/'));
      expect(modified.issued, equals(1234567890)); // unchanged
    });

    test('equality works correctly', () {
      final HandshakeDataModel h1 = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: true,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{'a': 'b'},
      );

      final HandshakeDataModel h2 = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: true,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{'a': 'b'},
      );

      expect(h1, equals(h2));
    });

    test('toString provides useful representation', () {
      final HandshakeDataModel handshake = HandshakeDataModel(
        headers: mockHeaders,
        time: testTime,
        address: testAddress,
        xdomain: true,
        secure: false,
        issued: 1234567890,
        url: '/socket.io/',
        query: <String, String>{},
      );

      final String str = handshake.toString();
      expect(str, contains('HandshakeDataModel'));
      expect(str, contains('xdomain: true'));
      expect(str, contains('/socket.io/'));
    });
  });

  group('HandshakeDataBuilder', () {
    late HttpHeaders mockHeaders;
    late DateTime testTime;
    late InternetAddress testAddress;

    setUp(() {
      mockHeaders = MockHttpHeaders();
      testTime = DateTime(2024, 1, 1, 12, 0, 0);
      testAddress = InternetAddress('127.0.0.1');
    });

    test('builds valid HandshakeDataModel', () {
      final HandshakeDataModel handshake = HandshakeDataBuilder()
          .headers(mockHeaders)
          .time(testTime)
          .address(testAddress)
          .xdomain(true)
          .secure(false)
          .issued(1234567890)
          .url('/socket.io/')
          .addQuery('token', 'abc')
          .build();

      expect(handshake.xdomain, isTrue);
      expect(handshake.query, equals(<String, String>{'token': 'abc'}));
    });

    test('queryMap adds multiple query parameters', () {
      final HandshakeDataModel handshake = HandshakeDataBuilder()
          .headers(mockHeaders)
          .time(testTime)
          .address(testAddress)
          .issued(1234567890)
          .url('/socket.io/')
          .queryMap(<String, String>{'a': '1', 'b': '2'}).build();

      expect(handshake.query, equals(<String, String>{'a': '1', 'b': '2'}));
    });

    test('throws StateError when required fields missing', () {
      expect(
        () => HandshakeDataBuilder().build(),
        throwsStateError,
      );
    });

    test('auth sets authentication data', () {
      final HandshakeDataModel handshake = HandshakeDataBuilder()
          .headers(mockHeaders)
          .time(testTime)
          .address(testAddress)
          .issued(1234567890)
          .url('/socket.io/')
          .auth(<String, Object?>{'userId': 123}).build();

      expect(handshake.auth, equals(<String, Object?>{'userId': 123}));
    });
  });
}
