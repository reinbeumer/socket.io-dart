import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/connection_id_vo.dart';

void main() {
  group('ConnectionId', () {
    test('creates valid ConnectionId from non-empty string', () {
      final ConnectionId id = ConnectionId('test-id-123');
      expect(id.value, equals('test-id-123'));
      expect(id.toString(), equals('test-id-123'));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => ConnectionId(''), throwsArgumentError);
    });

    test('equality works correctly', () {
      final ConnectionId id1 = ConnectionId('same-id');
      final ConnectionId id2 = ConnectionId('same-id');
      final ConnectionId id3 = ConnectionId('different-id');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });

    test('hashCode works correctly', () {
      final ConnectionId id1 = ConnectionId('same-id');
      final ConnectionId id2 = ConnectionId('same-id');

      expect(id1.hashCode, equals(id2.hashCode));
    });

    test('unchecked constructor allows any value', () {
      const ConnectionId id = ConnectionId.unchecked('');
      expect(id.value, equals(''));
    });
  });
}
