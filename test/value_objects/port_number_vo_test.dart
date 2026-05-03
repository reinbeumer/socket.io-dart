import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/port_number_vo.dart';

void main() {
  group('PortNumber', () {
    test('creates valid PortNumber in range', () {
      final PortNumber port = PortNumber(8080);
      expect(port.value, equals(8080));
      expect(port.toString(), equals('8080'));
    });

    test('accepts minimum port 1', () {
      final PortNumber port = PortNumber(1);
      expect(port.value, equals(1));
    });

    test('accepts maximum port 65535', () {
      final PortNumber port = PortNumber(65535);
      expect(port.value, equals(65535));
    });

    test('throws ArgumentError for port 0', () {
      expect(() => PortNumber(0), throwsArgumentError);
    });

    test('throws ArgumentError for negative port', () {
      expect(() => PortNumber(-1), throwsArgumentError);
    });

    test('throws ArgumentError for port > 65535', () {
      expect(() => PortNumber(65536), throwsArgumentError);
      expect(() => PortNumber(100000), throwsArgumentError);
    });

    test('has HTTP port constant', () {
      expect(PortNumber.http.value, equals(80));
    });

    test('has HTTPS port constant', () {
      expect(PortNumber.https.value, equals(443));
    });

    test('has dev port constant', () {
      expect(PortNumber.dev.value, equals(3000));
    });

    test('has alternative HTTP port constant', () {
      expect(PortNumber.altHttp.value, equals(8080));
    });

    test('equality works correctly', () {
      final PortNumber port1 = PortNumber(8080);
      final PortNumber port2 = PortNumber(8080);
      final PortNumber port3 = PortNumber(3000);

      expect(port1, equals(port2));
      expect(port1, isNot(equals(port3)));
    });

    test('hashCode works correctly', () {
      final PortNumber port1 = PortNumber(8080);
      final PortNumber port2 = PortNumber(8080);

      expect(port1.hashCode, equals(port2.hashCode));
    });

    test('unchecked constructor allows any value', () {
      const PortNumber port = PortNumber.unchecked(0);
      expect(port.value, equals(0));
    });

    test('common ports work', () {
      expect(PortNumber(80), equals(PortNumber.http));
      expect(PortNumber(443), equals(PortNumber.https));
      expect(PortNumber(3000), equals(PortNumber.dev));
    });
  });
}
