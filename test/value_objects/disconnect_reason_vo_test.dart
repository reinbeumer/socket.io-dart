import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/disconnect_reason_vo.dart';

void main() {
  group('DisconnectReasonType', () {
    test('enum has all expected values', () {
      expect(DisconnectReasonType.values.length, equals(10));
      expect(DisconnectReasonType.values, contains(DisconnectReasonType.clientDisconnect));
      expect(DisconnectReasonType.values, contains(DisconnectReasonType.serverDisconnect));
      expect(DisconnectReasonType.values, contains(DisconnectReasonType.pingTimeout));
    });

    test('value returns correct string', () {
      expect(DisconnectReasonType.clientDisconnect.value, equals('client disconnect'));
      expect(DisconnectReasonType.serverDisconnect.value, equals('server disconnect'));
      expect(DisconnectReasonType.pingTimeout.value, equals('ping timeout'));
      expect(DisconnectReasonType.transportClose.value, equals('transport close'));
    });

    test('fromString creates correct type', () {
      expect(DisconnectReasonTypeHelper.fromString('client disconnect'), equals(DisconnectReasonType.clientDisconnect));
      expect(DisconnectReasonTypeHelper.fromString('server disconnect'), equals(DisconnectReasonType.serverDisconnect));
      expect(DisconnectReasonTypeHelper.fromString('ping timeout'), equals(DisconnectReasonType.pingTimeout));
    });

    test('fromString is case insensitive', () {
      expect(DisconnectReasonTypeHelper.fromString('CLIENT DISCONNECT'), equals(DisconnectReasonType.clientDisconnect));
      expect(DisconnectReasonTypeHelper.fromString('Ping Timeout'), equals(DisconnectReasonType.pingTimeout));
    });

    test('fromString throws for invalid reason', () {
      expect(() => DisconnectReasonTypeHelper.fromString('invalid reason'), throwsArgumentError);
    });
  });

  group('DisconnectReason', () {
    test('creates from DisconnectReasonType', () {
      const DisconnectReason reason = DisconnectReason(DisconnectReasonType.clientDisconnect);
      expect(reason.type, equals(DisconnectReasonType.clientDisconnect));
      expect(reason.value, equals('client disconnect'));
      expect(reason.details, isNull);
    });

    test('creates with details', () {
      const DisconnectReason reason = DisconnectReason(DisconnectReasonType.transportError, 'Connection lost');
      expect(reason.type, equals(DisconnectReasonType.transportError));
      expect(reason.details, equals('Connection lost'));
      expect(reason.value, equals('Connection lost'));
    });

    test('creates from standard string', () {
      final DisconnectReason reason = DisconnectReason.fromString('ping timeout');
      expect(reason.type, equals(DisconnectReasonType.pingTimeout));
      expect(reason.value, equals('ping timeout'));
    });

    test('creates from non-standard string', () {
      final DisconnectReason reason = DisconnectReason.fromString('custom error');
      expect(reason.type, equals(DisconnectReasonType.serverDisconnect));
      expect(reason.details, equals('custom error'));
      expect(reason.value, equals('custom error'));
    });

    test('has static constants', () {
      expect(DisconnectReason.clientDisconnect.type, equals(DisconnectReasonType.clientDisconnect));
      expect(DisconnectReason.serverDisconnect.type, equals(DisconnectReasonType.serverDisconnect));
      expect(DisconnectReason.pingTimeout.type, equals(DisconnectReasonType.pingTimeout));
      expect(DisconnectReason.transportClose.type, equals(DisconnectReasonType.transportClose));
      expect(DisconnectReason.transportError.type, equals(DisconnectReasonType.transportError));
    });

    test('equality works correctly', () {
      const DisconnectReason reason1 = DisconnectReason(DisconnectReasonType.clientDisconnect);
      const DisconnectReason reason2 = DisconnectReason(DisconnectReasonType.clientDisconnect);
      const DisconnectReason reason3 = DisconnectReason(DisconnectReasonType.serverDisconnect);

      expect(reason1, equals(reason2));
      expect(reason1, isNot(equals(reason3)));
    });

    test('equality considers details', () {
      const DisconnectReason reason1 = DisconnectReason(DisconnectReasonType.transportError, 'Error 1');
      const DisconnectReason reason2 = DisconnectReason(DisconnectReasonType.transportError, 'Error 1');
      const DisconnectReason reason3 = DisconnectReason(DisconnectReasonType.transportError, 'Error 2');

      expect(reason1, equals(reason2));
      expect(reason1, isNot(equals(reason3)));
    });

    test('hashCode works correctly', () {
      const DisconnectReason reason1 = DisconnectReason(DisconnectReasonType.clientDisconnect);
      const DisconnectReason reason2 = DisconnectReason(DisconnectReasonType.clientDisconnect);

      expect(reason1.hashCode, equals(reason2.hashCode));
    });

    test('toString returns value', () {
      const DisconnectReason reason = DisconnectReason(DisconnectReasonType.pingTimeout);
      expect(reason.toString(), equals('ping timeout'));
    });

    test('toString returns details when provided', () {
      const DisconnectReason reason = DisconnectReason(DisconnectReasonType.serverDisconnect, 'Custom message');
      expect(reason.toString(), equals('Custom message'));
    });

    test('all enum types covered', () {
      for (final DisconnectReasonType type in DisconnectReasonType.values) {
        expect(type.value, isNotEmpty);
      }
    });
  });
}
