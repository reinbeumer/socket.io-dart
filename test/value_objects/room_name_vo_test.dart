import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/room_name_vo.dart';

void main() {
  group('RoomName', () {
    test('creates valid RoomName from non-empty string', () {
      final RoomName room = RoomName('room1');
      expect(room.value, equals('room1'));
      expect(room.toString(), equals('room1'));
    });

    test('accepts room names with special characters', () {
      final RoomName room = RoomName('room-1_test');
      expect(room.value, equals('room-1_test'));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => RoomName(''), throwsArgumentError);
    });

    test('equality works correctly', () {
      final RoomName room1 = RoomName('same-room');
      final RoomName room2 = RoomName('same-room');
      final RoomName room3 = RoomName('different-room');

      expect(room1, equals(room2));
      expect(room1, isNot(equals(room3)));
    });

    test('hashCode works correctly', () {
      final RoomName room1 = RoomName('same-room');
      final RoomName room2 = RoomName('same-room');

      expect(room1.hashCode, equals(room2.hashCode));
    });

    test('unchecked constructor allows any value', () {
      const RoomName room = RoomName.unchecked('');
      expect(room.value, equals(''));
    });
  });
}
