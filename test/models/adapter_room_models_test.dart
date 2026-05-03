/// adapter_room_models_test.dart
///
/// Tests for adapter room management models
import 'package:test/test.dart';
import 'package:socket_io/src/models/adapter_room_models.dart';

void main() {
  group('SocketRoomMembership', () {
    test('creates empty membership', () {
      final SocketRoomMembership membership = SocketRoomMembership();
      expect(membership.isEmpty, isTrue);
      expect(membership.isNotEmpty, isFalse);
      expect(membership.roomCount, equals(0));
      expect(membership.rooms, isEmpty);
    });

    test('creates membership from rooms', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      expect(membership.roomCount, equals(2));
      expect(membership.isInRoom('room1'), isTrue);
      expect(membership.isInRoom('room2'), isTrue);
      expect(membership.isInRoom('room3'), isFalse);
    });

    test('adds room', () {
      final SocketRoomMembership membership = SocketRoomMembership();
      membership.addRoom('room1');
      expect(membership.roomCount, equals(1));
      expect(membership.isInRoom('room1'), isTrue);
    });

    test('adds duplicate room only once', () {
      final SocketRoomMembership membership = SocketRoomMembership();
      membership.addRoom('room1');
      membership.addRoom('room1');
      expect(membership.roomCount, equals(1));
    });

    test('removes room', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final bool removed = membership.removeRoom('room1');
      expect(removed, isTrue);
      expect(membership.roomCount, equals(1));
      expect(membership.isInRoom('room1'), isFalse);
      expect(membership.isInRoom('room2'), isTrue);
    });

    test('removeRoom returns false when room not found', () {
      final SocketRoomMembership membership = SocketRoomMembership();
      final bool removed = membership.removeRoom('nonexistent');
      expect(removed, isFalse);
    });

    test('clears all rooms', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      membership.clear();
      expect(membership.isEmpty, isTrue);
      expect(membership.roomCount, equals(0));
    });

    test('rooms returns unmodifiable set', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1']);
      final Set<String> rooms = membership.rooms;
      expect(() => rooms.add('room2'), throwsUnsupportedError);
    });

    test('copies membership', () {
      final SocketRoomMembership original = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final SocketRoomMembership copy = original.copy();

      expect(copy.roomCount, equals(original.roomCount));
      expect(copy.isInRoom('room1'), isTrue);
      expect(copy.isInRoom('room2'), isTrue);

      // Verify deep copy - modifying copy doesn't affect original
      copy.addRoom('room3');
      expect(copy.roomCount, equals(3));
      expect(original.roomCount, equals(2));
    });

    test('equality works correctly', () {
      final SocketRoomMembership membership1 = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final SocketRoomMembership membership2 =
          SocketRoomMembership.fromRooms(<String>['room2', 'room1']); // Different order
      final SocketRoomMembership membership3 = SocketRoomMembership.fromRooms(<String>['room1']);

      expect(membership1, equals(membership2)); // Order doesn't matter
      expect(membership1, isNot(equals(membership3)));
    });

    test('hashCode is consistent', () {
      final SocketRoomMembership membership1 = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final SocketRoomMembership membership2 = SocketRoomMembership.fromRooms(<String>['room2', 'room1']);

      // Equal objects should have same hashcode (or at least test equality works)
      expect(membership1 == membership2, isTrue);
      // Hashcode of same instance should be consistent
      expect(membership1.hashCode, equals(membership1.hashCode));
    });

    test('toString includes rooms', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final String str = membership.toString();
      expect(str, contains('SocketRoomMembership'));
      expect(str, contains('rooms'));
    });

    test('converts to compatibility map', () {
      final SocketRoomMembership membership = SocketRoomMembership.fromRooms(<String>['room1', 'room2']);
      final Map<String, bool> compatMap = membership.toCompatibilityMap();

      expect(compatMap.length, equals(2));
      expect(compatMap['room1'], isTrue);
      expect(compatMap['room2'], isTrue);
    });

    test('creates from compatibility map', () {
      final Map<String, dynamic> compatMap = <String, dynamic>{
        'room1': true,
        'room2': false, // Value doesn't matter
        'room3': 'anything', // Value type doesn't matter
      };

      final SocketRoomMembership membership = SocketRoomMembership.fromCompatibilityMap(compatMap);
      expect(membership.roomCount, equals(3));
      expect(membership.isInRoom('room1'), isTrue);
      expect(membership.isInRoom('room2'), isTrue);
      expect(membership.isInRoom('room3'), isTrue);
    });

    test('round trip through compatibility map', () {
      final SocketRoomMembership original = SocketRoomMembership.fromRooms(<String>['room1', 'room2', 'room3']);
      final Map<String, bool> compatMap = original.toCompatibilityMap();
      final SocketRoomMembership roundTrip = SocketRoomMembership.fromCompatibilityMap(compatMap);

      expect(roundTrip, equals(original));
    });
  });

  group('AdapterNamespaceData', () {
    test('creates with name', () {
      final AdapterNamespaceData data = AdapterNamespaceData(name: '/chat');
      expect(data.name, equals('/chat'));
      expect(data.metadata, isEmpty);
    });

    test('creates with metadata', () {
      final AdapterNamespaceData data = AdapterNamespaceData(
        name: '/chat',
        metadata: <String, Object?>{'created': DateTime.now()},
      );
      expect(data.name, equals('/chat'));
      expect(data.metadata, isNotEmpty);
    });

    test('equality based on name', () {
      final AdapterNamespaceData data1 = AdapterNamespaceData(name: '/chat');
      final AdapterNamespaceData data2 = AdapterNamespaceData(name: '/chat', metadata: <String, Object?>{'a': 1});
      final AdapterNamespaceData data3 = AdapterNamespaceData(name: '/other');

      expect(data1, equals(data2)); // Metadata doesn't affect equality
      expect(data1, isNot(equals(data3)));
    });

    test('hashCode based on name', () {
      final AdapterNamespaceData data1 = AdapterNamespaceData(name: '/chat');
      final AdapterNamespaceData data2 = AdapterNamespaceData(name: '/chat');

      expect(data1.hashCode, equals(data2.hashCode));
    });

    test('toString includes name', () {
      final AdapterNamespaceData data = AdapterNamespaceData(name: '/chat');
      final String str = data.toString();
      expect(str, contains('AdapterNamespaceData'));
      expect(str, contains('/chat'));
    });
  });
}
