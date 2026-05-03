import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/transport_name_vo.dart';

void main() {
  group('TransportType', () {
    test('enum has all expected values', () {
      expect(TransportType.values, contains(TransportType.websocket));
      expect(TransportType.values, contains(TransportType.polling));
      expect(TransportType.values, contains(TransportType.webtransport));
    });

    test('value returns correct string', () {
      expect(TransportType.websocket.value, equals('websocket'));
      expect(TransportType.polling.value, equals('polling'));
      expect(TransportType.webtransport.value, equals('webtransport'));
    });

    test('fromString creates correct type', () {
      expect(TransportTypeHelper.fromString('websocket'), equals(TransportType.websocket));
      expect(TransportTypeHelper.fromString('polling'), equals(TransportType.polling));
      expect(TransportTypeHelper.fromString('webtransport'), equals(TransportType.webtransport));
    });

    test('fromString handles aliases', () {
      expect(TransportTypeHelper.fromString('ws'), equals(TransportType.websocket));
    });

    test('fromString throws for invalid type', () {
      expect(() => TransportTypeHelper.fromString('invalid'), throwsArgumentError);
    });
  });

  group('TransportName', () {
    test('creates from TransportType', () {
      const TransportName name = TransportName(TransportType.websocket);
      expect(name.type, equals(TransportType.websocket));
      expect(name.value, equals('websocket'));
    });

    test('creates from string', () {
      final TransportName name = TransportName.fromString('polling');
      expect(name.type, equals(TransportType.polling));
      expect(name.value, equals('polling'));
    });

    test('has static constants', () {
      expect(TransportName.websocket.type, equals(TransportType.websocket));
      expect(TransportName.polling.type, equals(TransportType.polling));
      expect(TransportName.webtransport.type, equals(TransportType.webtransport));
    });

    test('equality works correctly', () {
      const TransportName name1 = TransportName(TransportType.websocket);
      const TransportName name2 = TransportName(TransportType.websocket);
      const TransportName name3 = TransportName(TransportType.polling);

      expect(name1, equals(name2));
      expect(name1, isNot(equals(name3)));
    });

    test('hashCode works correctly', () {
      const TransportName name1 = TransportName(TransportType.websocket);
      const TransportName name2 = TransportName(TransportType.websocket);

      expect(name1.hashCode, equals(name2.hashCode));
    });

    test('toString returns value', () {
      const TransportName name = TransportName(TransportType.websocket);
      expect(name.toString(), equals('websocket'));
    });

    test('static constants work', () {
      expect(TransportName.websocket.value, equals('websocket'));
      expect(TransportName.polling.value, equals('polling'));
    });
  });
}
