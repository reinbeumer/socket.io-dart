/// Tests for packet data models.
library packet_data_models_test;

import 'package:test/test.dart';
import 'package:socket_io/src/models/packet_data_models.dart';
import 'package:socket_io/src/value_objects/disconnect_reason_vo.dart';
import 'package:socket_io/src/value_objects/event_arguments_vo.dart';

void main() {
  group('ConnectPacketData', () {
    test('creates with all fields', () {
      final ConnectPacketData data = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
        query: <String, Object?>{'userId': '123'},
        metadata: <String, Object?>{'version': '1.0'},
      );

      expect(data.auth, <String, Object?>{'token': 'abc123'});
      expect(data.query, <String, Object?>{'userId': '123'});
      expect(data.metadata, <String, Object?>{'version': '1.0'});
    });

    test('creates with null fields', () {
      const ConnectPacketData data = ConnectPacketData();

      expect(data.auth, isNull);
      expect(data.query, isNull);
      expect(data.metadata, isNull);
    });

    test('converts to and from JSON', () {
      final ConnectPacketData original = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
        query: <String, Object?>{'userId': '123'},
      );

      final Map<String, dynamic> json = original.toJson();
      final ConnectPacketData restored = ConnectPacketData.fromJson(json);

      expect(restored, equals(original));
    });

    test('toJson omits null fields', () {
      const ConnectPacketData data = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
      );

      final Map<String, dynamic> json = data.toJson();

      expect(json.containsKey('auth'), isTrue);
      expect(json.containsKey('query'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });

    test('equality works correctly', () {
      final ConnectPacketData data1 = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
      );
      final ConnectPacketData data2 = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
      );
      final ConnectPacketData data3 = ConnectPacketData(
        auth: <String, Object?>{'token': 'different'},
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('hashCode is consistent', () {
      final ConnectPacketData data = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
      );

      // HashCode should be consistent for same object
      expect(data.hashCode, equals(data.hashCode));
    });

    test('toString provides meaningful output', () {
      final ConnectPacketData data = ConnectPacketData(
        auth: <String, Object?>{'token': 'abc123'},
        query: <String, Object?>{'userId': '123'},
      );

      final String str = data.toString();
      expect(str, contains('ConnectPacketData'));
    });
  });

  group('DisconnectPacketData', () {
    test('creates from DisconnectReason (typed)', () {
      final DisconnectPacketData data = DisconnectPacketData(reason: DisconnectReason.clientDisconnect);

      expect(data.reason, 'client disconnect');
      expect(data.typedReason, equals(DisconnectReason.clientDisconnect));
      expect(data.description, isNull);
      expect(data.metadata, isNull);
    });

    test('creates with all fields', () {
      final DisconnectPacketData data = DisconnectPacketData(
        reason: DisconnectReason(DisconnectReasonType.serverDisconnect, 'custom details'),
        description: 'Maintenance',
        metadata: <String, Object?>{'time': '10:00'},
      );

      expect(data.reason, 'custom details');
      expect(data.description, 'Maintenance');
      expect(data.metadata, <String, Object?>{'time': '10:00'});
    });

    test('fromReasonString factory creates correctly', () {
      final DisconnectPacketData data = DisconnectPacketData.fromReasonString('ping timeout');

      expect(data.reason, 'ping timeout');
      expect(data.reasonValue.type, DisconnectReasonType.pingTimeout);
      expect(data.description, isNull);
    });

    test('fromJson handles string', () {
      final DisconnectPacketData data = DisconnectPacketData.fromJson('client disconnect');

      expect(data.reason, 'client disconnect');
      expect(data.reasonValue.type, DisconnectReasonType.clientDisconnect);
    });

    test('fromJson handles map', () {
      final DisconnectPacketData data = DisconnectPacketData.fromJson(
        <String, dynamic>{
          'reason': 'server disconnect',
          'description': 'Maintenance',
        },
      );

      expect(data.reason, 'server disconnect');
      expect(data.reasonValue.type, DisconnectReasonType.serverDisconnect);
      expect(data.description, 'Maintenance');
    });

    test('fromJson handles null', () {
      final DisconnectPacketData data = DisconnectPacketData.fromJson(null);

      expect(data.reason, 'unknown');
    });

    test('toJson returns string for simple case', () {
      final DisconnectPacketData data = DisconnectPacketData(reason: DisconnectReason.clientDisconnect);

      final Object json = data.toJson();

      expect(json, 'client disconnect');
    });

    test('toJson returns map for complex case', () {
      final DisconnectPacketData data = DisconnectPacketData(
        reason: DisconnectReason.serverDisconnect,
        description: 'Maintenance',
      );

      final Object json = data.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect((json as Map<String, dynamic>)['reason'], 'server disconnect');
      expect(json['description'], 'Maintenance');
    });

    test('equality works correctly', () {
      final DisconnectPacketData data1 = DisconnectPacketData(reason: DisconnectReason.clientDisconnect);
      final DisconnectPacketData data2 = DisconnectPacketData(reason: DisconnectReason.clientDisconnect);
      final DisconnectPacketData data3 = DisconnectPacketData(reason: DisconnectReason.serverDisconnect);

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('reasonValue getter converts from string', () {
      // ignore: deprecated_member_use
      final DisconnectPacketData data = DisconnectPacketData.fromString(reason: 'transport error');

      expect(data.reasonValue.type, DisconnectReasonType.transportError);
      expect(data.reasonValue.value, 'transport error');
    });

    test('supports backward compatibility with string constructor', () {
      // ignore: deprecated_member_use
      final DisconnectPacketData data = DisconnectPacketData.fromString(
        reason: 'forced close',
        description: 'Server maintenance',
      );

      expect(data.reason, 'forced close');
      expect(data.description, 'Server maintenance');
    });
  });

  group('EventPacketData', () {
    test('creates with event name and arguments', () {
      final EventPacketData data = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello', 42]),
      );

      expect(data.eventName, 'message');
      expect(data.arguments.length, 2);
      expect(data.arguments[0], 'Hello');
      expect(data.arguments[1], 42);
    });

    test('fromList creates correctly', () {
      final EventPacketData data = EventPacketData.fromList(<dynamic>['message', 'Hello', 42]);

      expect(data.eventName, 'message');
      expect(data.arguments.length, 2);
      expect(data.arguments[0], 'Hello');
      expect(data.arguments[1], 42);
    });

    test('fromList throws for empty list', () {
      expect(
        () => EventPacketData.fromList(<dynamic>[]),
        throwsArgumentError,
      );
    });

    test('withoutArgs factory creates correctly', () {
      final EventPacketData data = EventPacketData.withoutArgs('ping');

      expect(data.eventName, 'ping');
      expect(data.arguments.isEmpty, isTrue);
    });

    test('single factory creates correctly', () {
      final EventPacketData data = EventPacketData.single('update', 42);

      expect(data.eventName, 'update');
      expect(data.arguments.length, 1);
      expect(data.arguments[0], 42);
    });

    test('toList returns correct format', () {
      final EventPacketData data = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello', 42]),
      );

      final List<Object?> list = data.toList();

      expect(list, <Object?>['message', 'Hello', 42]);
    });

    test('toJson returns list format', () {
      final EventPacketData data = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello']),
      );

      final List<Object?> json = data.toJson();

      expect(json, <Object?>['message', 'Hello']);
    });

    test('equality works correctly', () {
      final EventPacketData data1 = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello']),
      );
      final EventPacketData data2 = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello']),
      );
      final EventPacketData data3 = EventPacketData(
        eventName: 'different',
        arguments: EventArguments(<Object?>['Hello']),
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('toString provides meaningful output', () {
      final EventPacketData data = EventPacketData(
        eventName: 'message',
        arguments: EventArguments(<Object?>['Hello', 42]),
      );

      final String str = data.toString();
      expect(str, contains('EventPacketData'));
      expect(str, contains('message'));
      expect(str, contains('2 args'));
    });
  });

  group('AckPacketData', () {
    test('creates with arguments', () {
      final AckPacketData data = AckPacketData(
        arguments: EventArguments(<Object?>['success', 200]),
      );

      expect(data.arguments.length, 2);
      expect(data.arguments[0], 'success');
      expect(data.arguments[1], 200);
    });

    test('fromList creates correctly', () {
      final AckPacketData data = AckPacketData.fromList(<dynamic>['success', 200]);

      expect(data.arguments.length, 2);
      expect(data.arguments[0], 'success');
      expect(data.arguments[1], 200);
    });

    test('empty factory creates correctly', () {
      final AckPacketData data = AckPacketData.empty();

      expect(data.arguments.isEmpty, isTrue);
    });

    test('single factory creates correctly', () {
      final AckPacketData data = AckPacketData.single('ok');

      expect(data.arguments.length, 1);
      expect(data.arguments[0], 'ok');
    });

    test('success factory with no data', () {
      final AckPacketData data = AckPacketData.success();

      expect(data.arguments.isEmpty, isTrue);
    });

    test('success factory with data', () {
      final AckPacketData data = AckPacketData.success('ok');

      expect(data.arguments.length, 1);
      expect(data.arguments[0], 'ok');
    });

    test('error factory creates correctly', () {
      final AckPacketData data = AckPacketData.error('Something went wrong');

      expect(data.arguments.length, 1);
      expect(data.arguments[0], 'Something went wrong');
    });

    test('toList returns arguments', () {
      final AckPacketData data = AckPacketData(
        arguments: EventArguments(<Object?>['success', 200]),
      );

      final List<Object?> list = data.toList();

      expect(list, <Object?>['success', 200]);
    });

    test('equality works correctly', () {
      final AckPacketData data1 = AckPacketData(
        arguments: EventArguments(<Object?>['success']),
      );
      final AckPacketData data2 = AckPacketData(
        arguments: EventArguments(<Object?>['success']),
      );
      final AckPacketData data3 = AckPacketData(
        arguments: EventArguments(<Object?>['error']),
      );

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });
  });

  group('ConnectErrorPacketData', () {
    test('creates with message', () {
      const ConnectErrorPacketData data = ConnectErrorPacketData(message: 'Authentication failed');

      expect(data.message, 'Authentication failed');
      expect(data.code, isNull);
      expect(data.details, isNull);
    });

    test('creates with all fields', () {
      final ConnectErrorPacketData data = ConnectErrorPacketData(
        message: 'Authentication failed',
        code: 'AUTH_ERROR',
        details: <String, Object?>{'reason': 'Invalid token'},
      );

      expect(data.message, 'Authentication failed');
      expect(data.code, 'AUTH_ERROR');
      expect(data.details, <String, Object?>{'reason': 'Invalid token'});
    });

    test('fromMessage factory creates correctly', () {
      final ConnectErrorPacketData data = ConnectErrorPacketData.fromMessage('Connection failed');

      expect(data.message, 'Connection failed');
      expect(data.code, isNull);
    });

    test('fromJson handles string', () {
      final ConnectErrorPacketData data = ConnectErrorPacketData.fromJson('Authentication failed');

      expect(data.message, 'Authentication failed');
    });

    test('fromJson handles map', () {
      final ConnectErrorPacketData data = ConnectErrorPacketData.fromJson(
        <String, dynamic>{
          'message': 'Authentication failed',
          'code': 'AUTH_ERROR',
        },
      );

      expect(data.message, 'Authentication failed');
      expect(data.code, 'AUTH_ERROR');
    });

    test('fromJson handles null', () {
      final ConnectErrorPacketData data = ConnectErrorPacketData.fromJson(null);

      expect(data.message, 'Unknown error');
    });

    test('toJson returns string for simple case', () {
      const ConnectErrorPacketData data = ConnectErrorPacketData(message: 'Authentication failed');

      final Object json = data.toJson();

      expect(json, 'Authentication failed');
    });

    test('toJson returns map for complex case', () {
      const ConnectErrorPacketData data = ConnectErrorPacketData(
        message: 'Authentication failed',
        code: 'AUTH_ERROR',
      );

      final Object json = data.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(
        (json as Map<String, dynamic>)['message'],
        'Authentication failed',
      );
      expect(json['code'], 'AUTH_ERROR');
    });

    test('equality works correctly', () {
      const ConnectErrorPacketData data1 = ConnectErrorPacketData(message: 'Authentication failed');
      const ConnectErrorPacketData data2 = ConnectErrorPacketData(message: 'Authentication failed');
      const ConnectErrorPacketData data3 = ConnectErrorPacketData(message: 'Connection refused');

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('toString provides meaningful output', () {
      const ConnectErrorPacketData data = ConnectErrorPacketData(message: 'Authentication failed');

      final String str = data.toString();
      expect(str, contains('ConnectErrorPacketData'));
      expect(str, contains('Authentication failed'));
    });
  });
}
