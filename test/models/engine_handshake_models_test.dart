/// engine_handshake_models_test.dart
///
/// Tests for Engine.IO handshake models
library engine_handshake_models_test;

import 'package:test/test.dart';
import 'package:socket_io/src/models/engine_handshake_models.dart';

void main() {
  group('EngineHandshakeData', () {
    test('creates instance with required fields', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-session-123',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      expect(data.sid, equals('test-session-123'));
      expect(data.upgrades, equals(<String>['websocket']));
      expect(data.pingInterval, equals(25000));
      expect(data.pingTimeout, equals(20000));
      expect(data.maxHttpBufferSize, isNull);
    });

    test('creates instance with optional maxHttpBufferSize', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-session-123',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
        maxHttpBufferSize: 1048576,
      );

      expect(data.maxHttpBufferSize, equals(1048576));
    });

    test('creates from JSON with all fields', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'sid': 'test-session-456',
        'upgrades': <String>['websocket'],
        'pingInterval': 30000,
        'pingTimeout': 15000,
        'maxHttpBufferSize': 2097152,
      };

      final EngineHandshakeData data = EngineHandshakeData.fromJson(json);

      expect(data.sid, equals('test-session-456'));
      expect(data.upgrades, equals(<String>['websocket']));
      expect(data.pingInterval, equals(30000));
      expect(data.pingTimeout, equals(15000));
      expect(data.maxHttpBufferSize, equals(2097152));
    });

    test('creates from JSON without optional fields', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'sid': 'test-session-789',
        'upgrades': <String>[],
        'pingInterval': 25000,
        'pingTimeout': 20000,
      };

      final EngineHandshakeData data = EngineHandshakeData.fromJson(json);

      expect(data.sid, equals('test-session-789'));
      expect(data.upgrades, isEmpty);
      expect(data.pingInterval, equals(25000));
      expect(data.pingTimeout, equals(20000));
      expect(data.maxHttpBufferSize, isNull);
    });

    test('converts to JSON with all fields', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-session-abc',
        upgrades: <String>['websocket', 'polling'],
        pingInterval: 25000,
        pingTimeout: 20000,
        maxHttpBufferSize: 1048576,
      );

      final Map<String, dynamic> json = data.toJson();

      expect(json['sid'], equals('test-session-abc'));
      expect(json['upgrades'], equals(<String>['websocket', 'polling']));
      expect(json['pingInterval'], equals(25000));
      expect(json['pingTimeout'], equals(20000));
      expect(json['maxHttpBufferSize'], equals(1048576));
    });

    test('converts to JSON without optional fields', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-session-def',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      final Map<String, dynamic> json = data.toJson();

      expect(json.containsKey('maxHttpBufferSize'), isFalse);
    });

    test('equality works correctly', () {
      const EngineHandshakeData data1 = EngineHandshakeData(
        sid: 'same-sid',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      const EngineHandshakeData data2 = EngineHandshakeData(
        sid: 'same-sid',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('inequality works correctly', () {
      const EngineHandshakeData data1 = EngineHandshakeData(
        sid: 'sid-1',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      const EngineHandshakeData data2 = EngineHandshakeData(
        sid: 'sid-2',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      expect(data1, isNot(equals(data2)));
    });

    test('toString includes all fields', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-sid',
        upgrades: <String>['websocket'],
        pingInterval: 25000,
        pingTimeout: 20000,
        maxHttpBufferSize: 1048576,
      );

      final String str = data.toString();

      expect(str, contains('test-sid'));
      expect(str, contains('websocket'));
      expect(str, contains('25000'));
      expect(str, contains('20000'));
      expect(str, contains('1048576'));
    });

    test('handles empty upgrades list', () {
      const EngineHandshakeData data = EngineHandshakeData(
        sid: 'test-sid',
        upgrades: <String>[],
        pingInterval: 25000,
        pingTimeout: 20000,
      );

      expect(data.upgrades, isEmpty);

      final Map<String, dynamic> json = data.toJson();
      expect(json['upgrades'], isEmpty);
    });
  });

  group('EngineHandshakeRequest', () {
    test('creates instance with required fields', () {
      const EngineHandshakeRequest request = EngineHandshakeRequest(
        transport: 'websocket',
      );

      expect(request.transport, equals('websocket'));
      expect(request.supportsBinary, isTrue);
      expect(request.eid, isNull);
      expect(request.sid, isNull);
      expect(request.isReconnection, isFalse);
    });

    test('creates instance with all fields', () {
      const EngineHandshakeRequest request = EngineHandshakeRequest(
        transport: 'polling',
        supportsBinary: false,
        eid: '4',
        sid: 'existing-session-123',
      );

      expect(request.transport, equals('polling'));
      expect(request.supportsBinary, isFalse);
      expect(request.eid, equals('4'));
      expect(request.sid, equals('existing-session-123'));
      expect(request.isReconnection, isTrue);
    });

    test('creates from query parameters with all fields', () {
      final Map<String, dynamic> query = <String, dynamic>{
        'transport': 'websocket',
        'b64': '0',
        'EIO': '4',
        'sid': 'reconnect-session-456',
      };

      final EngineHandshakeRequest request = EngineHandshakeRequest.fromQuery(query);

      expect(request.transport, equals('websocket'));
      expect(request.supportsBinary, isTrue);
      expect(request.eid, equals('4'));
      expect(request.sid, equals('reconnect-session-456'));
      expect(request.isReconnection, isTrue);
    });

    test('creates from query with b64=1 disables binary support', () {
      final Map<String, dynamic> query = <String, dynamic>{
        'transport': 'polling',
        'b64': '1',
      };

      final EngineHandshakeRequest request = EngineHandshakeRequest.fromQuery(query);

      expect(request.supportsBinary, isFalse);
    });

    test('creates from query with missing b64 enables binary support', () {
      final Map<String, dynamic> query = <String, dynamic>{
        'transport': 'websocket',
      };

      final EngineHandshakeRequest request = EngineHandshakeRequest.fromQuery(query);

      expect(request.supportsBinary, isTrue);
    });

    test('defaults to polling transport when missing', () {
      final Map<String, dynamic> query = <String, dynamic>{};

      final EngineHandshakeRequest request = EngineHandshakeRequest.fromQuery(query);

      expect(request.transport, equals('polling'));
    });

    test('isReconnection is true when sid is present', () {
      const EngineHandshakeRequest request = EngineHandshakeRequest(
        transport: 'websocket',
        sid: 'some-session-id',
      );

      expect(request.isReconnection, isTrue);
    });

    test('isReconnection is false when sid is absent', () {
      const EngineHandshakeRequest request = EngineHandshakeRequest(
        transport: 'websocket',
      );

      expect(request.isReconnection, isFalse);
    });

    test('equality works correctly', () {
      const EngineHandshakeRequest request1 = EngineHandshakeRequest(
        transport: 'websocket',
        supportsBinary: true,
        eid: '4',
        sid: 'session-abc',
      );

      const EngineHandshakeRequest request2 = EngineHandshakeRequest(
        transport: 'websocket',
        supportsBinary: true,
        eid: '4',
        sid: 'session-abc',
      );

      expect(request1, equals(request2));
      expect(request1.hashCode, equals(request2.hashCode));
    });

    test('inequality works correctly', () {
      const EngineHandshakeRequest request1 = EngineHandshakeRequest(
        transport: 'websocket',
      );

      const EngineHandshakeRequest request2 = EngineHandshakeRequest(
        transport: 'polling',
      );

      expect(request1, isNot(equals(request2)));
    });

    test('toString includes all fields', () {
      const EngineHandshakeRequest request = EngineHandshakeRequest(
        transport: 'websocket',
        supportsBinary: true,
        eid: '4',
        sid: 'test-session',
      );

      final String str = request.toString();

      expect(str, contains('websocket'));
      expect(str, contains('true'));
      expect(str, contains('4'));
      expect(str, contains('test-session'));
      expect(str, contains('isReconnection'));
    });

    test('handles various protocol versions', () {
      const List<String> versions = <String>['3', '4', '5'];

      for (final String version in versions) {
        final EngineHandshakeRequest request = EngineHandshakeRequest(
          transport: 'websocket',
          eid: version,
        );

        expect(request.eid, equals(version));
      }
    });
  });
}
