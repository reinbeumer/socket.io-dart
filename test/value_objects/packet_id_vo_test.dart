import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/packet_id_vo.dart';

void main() {
  group('PacketId', () {
    test('creates valid PacketId from non-empty string', () {
      final PacketId id = PacketId('123');
      expect(id.value, equals('123'));
      expect(id.toString(), equals('123'));
    });

    test('creates PacketId from integer', () {
      final PacketId id = PacketId.fromInt(42);
      expect(id.value, equals('42'));
      expect(id.toInt(), equals(42));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => PacketId(''), throwsArgumentError);
    });

    test('throws ArgumentError for negative integer', () {
      expect(() => PacketId.fromInt(-1), throwsArgumentError);
    });

    test('toInt returns null for non-numeric string', () {
      final PacketId id = PacketId('abc');
      expect(id.toInt(), isNull);
    });

    test('toInt returns correct value for numeric string', () {
      final PacketId id = PacketId('999');
      expect(id.toInt(), equals(999));
    });

    test('equality works correctly', () {
      final PacketId id1 = PacketId('123');
      final PacketId id2 = PacketId('123');
      final PacketId id3 = PacketId('456');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });

    test('hashCode works correctly', () {
      final PacketId id1 = PacketId('123');
      final PacketId id2 = PacketId('123');

      expect(id1.hashCode, equals(id2.hashCode));
    });

    test('unchecked constructor allows any value', () {
      const PacketId id = PacketId.unchecked('');
      expect(id.value, equals(''));
    });
  });
}
