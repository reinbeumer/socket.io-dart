import 'package:test/test.dart';
import 'package:socket_io/src/models/room_management_models.dart';
import 'package:socket_io/src/value_objects/room_name_vo.dart';

void main() {
  group('RoomMembership', () {
    test('creates empty membership', () {
      final RoomMembership membership = RoomMembership();
      expect(membership.isEmpty, isTrue);
      expect(membership.length, equals(0));
    });

    test('creates from room names', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      expect(membership.length, equals(2));
      expect(membership.containsName('room1'), isTrue);
      expect(membership.containsName('room2'), isTrue);
    });

    test('creates from RoomName objects', () {
      final RoomMembership membership = RoomMembership.fromRooms(<RoomName>[
        RoomName('room1'),
        RoomName('room2'),
      ]);
      expect(membership.length, equals(2));
    });

    test('adds room', () {
      final RoomMembership membership = RoomMembership();
      membership.add(RoomName('room1'));
      expect(membership.containsName('room1'), isTrue);
      expect(membership.length, equals(1));
    });

    test('adds room by name', () {
      final RoomMembership membership = RoomMembership();
      membership.addByName('room1');
      expect(membership.containsName('room1'), isTrue);
    });

    test('removes room', () {
      final RoomMembership membership = RoomMembership();
      final RoomName room = RoomName('room1');
      membership.add(room);

      final bool removed = membership.remove(room);
      expect(removed, isTrue);
      expect(membership.isEmpty, isTrue);
    });

    test('removes room by name', () {
      final RoomMembership membership = RoomMembership();
      membership.addByName('room1');

      final bool removed = membership.removeByName('room1');
      expect(removed, isTrue);
    });

    test('contains checks membership', () {
      final RoomMembership membership = RoomMembership();
      final RoomName room = RoomName('room1');

      expect(membership.contains(room), isFalse);
      membership.add(room);
      expect(membership.contains(room), isTrue);
    });

    test('gets room by name', () {
      final RoomMembership membership = RoomMembership();
      membership.addByName('room1');

      final RoomName? room = membership.get('room1');
      expect(room, isNotNull);
      expect(room!.value, equals('room1'));
    });

    test('returns all rooms', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      expect(membership.rooms.length, equals(2));
    });

    test('returns all room names', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      expect(membership.roomNames, containsAll(<String>['room1', 'room2']));
    });

    test('converts to list', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      final List<String> list = membership.toList();
      expect(list, containsAll(<String>['room1', 'room2']));
    });

    test('converts to set', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      final Set<String> set = membership.toSet();
      expect(set, containsAll(<String>['room1', 'room2']));
    });

    test('clears all rooms', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1', 'room2']);
      membership.clear();
      expect(membership.isEmpty, isTrue);
    });

    test('copy creates independent copy', () {
      final RoomMembership original = RoomMembership.fromNames(<String>['room1']);
      final RoomMembership copy = original.copy();

      copy.addByName('room2');
      expect(original.length, equals(1));
      expect(copy.length, equals(2));
    });

    test('toString provides useful representation', () {
      final RoomMembership membership = RoomMembership.fromNames(<String>['room1']);
      expect(membership.toString(), contains('RoomMembership'));
      expect(membership.toString(), contains('room1'));
    });
  });

  group('RoomSocketCollection', () {
    test('creates empty collection', () {
      final RoomSocketCollection collection = RoomSocketCollection(RoomName('room1'));
      expect(collection.isEmpty, isTrue);
      expect(collection.roomName.value, equals('room1'));
    });

    test('creates from socket IDs', () {
      final RoomSocketCollection collection = RoomSocketCollection.fromIds(
        RoomName('room1'),
        <String>['socket1', 'socket2'],
      );
      expect(collection.length, equals(2));
    });

    test('adds socket', () {
      final RoomSocketCollection collection = RoomSocketCollection(RoomName('room1'));
      final bool added = collection.add('socket1');
      expect(added, isTrue);
      expect(collection.contains('socket1'), isTrue);
    });

    test('removes socket', () {
      final RoomSocketCollection collection = RoomSocketCollection(RoomName('room1'));
      collection.add('socket1');

      final bool removed = collection.remove('socket1');
      expect(removed, isTrue);
      expect(collection.isEmpty, isTrue);
    });

    test('returns socket IDs', () {
      final RoomSocketCollection collection = RoomSocketCollection.fromIds(
        RoomName('room1'),
        <String>['socket1', 'socket2'],
      );
      expect(collection.socketIds, containsAll(<String>['socket1', 'socket2']));
    });

    test('clears all sockets', () {
      final RoomSocketCollection collection = RoomSocketCollection.fromIds(
        RoomName('room1'),
        <String>['socket1', 'socket2'],
      );
      collection.clear();
      expect(collection.isEmpty, isTrue);
    });

    test('copy creates independent copy', () {
      final RoomSocketCollection original = RoomSocketCollection(RoomName('room1'));
      original.add('socket1');

      final RoomSocketCollection copy = original.copy();
      copy.add('socket2');

      expect(original.length, equals(1));
      expect(copy.length, equals(2));
    });

    test('toString provides useful representation', () {
      final RoomSocketCollection collection = RoomSocketCollection(RoomName('room1'));
      collection.add('socket1');
      expect(collection.toString(), contains('RoomSocketCollection'));
      expect(collection.toString(), contains('room1'));
    });
  });

  group('RoomManager', () {
    test('creates empty manager', () {
      final RoomManager manager = RoomManager();
      expect(manager.roomCount, equals(0));
      expect(manager.socketCount, equals(0));
    });

    test('joins socket to room', () {
      final RoomManager manager = RoomManager();
      manager.join('socket1', RoomName('room1'));

      expect(manager.isInRoom('socket1', RoomName('room1')), isTrue);
      expect(manager.roomCount, equals(1));
      expect(manager.socketCount, equals(1));
    });

    test('joins socket to room by name', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');

      expect(manager.isInRoomByName('socket1', 'room1'), isTrue);
    });

    test('joins multiple sockets to same room', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket2', 'room1');

      final Set<String> sockets = manager.getSocketsInRoomByName('room1');
      expect(sockets, containsAll(<String>['socket1', 'socket2']));
    });

    test('joins socket to multiple rooms', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket1', 'room2');

      final RoomMembership? membership = manager.getRoomsForSocket('socket1');
      expect(membership, isNotNull);
      expect(membership!.length, equals(2));
    });

    test('leaves room', () {
      final RoomManager manager = RoomManager();
      manager.join('socket1', RoomName('room1'));
      manager.leave('socket1', RoomName('room1'));

      expect(manager.isInRoom('socket1', RoomName('room1')), isFalse);
    });

    test('leaves room by name', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.leaveByName('socket1', 'room1');

      expect(manager.isInRoomByName('socket1', 'room1'), isFalse);
    });

    test('leaves all rooms', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket1', 'room2');
      manager.leaveAll('socket1');

      final RoomMembership? membership = manager.getRoomsForSocket('socket1');
      expect(membership, isNull);
      expect(manager.socketCount, equals(0));
    });

    test('gets sockets in room', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket2', 'room1');

      final Set<String> sockets = manager.getSocketsInRoom(RoomName('room1'));
      expect(sockets.length, equals(2));
    });

    test('gets rooms for socket', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket1', 'room2');

      final RoomMembership? membership = manager.getRoomsForSocket('socket1');
      expect(membership, isNotNull);
      expect(membership!.containsName('room1'), isTrue);
      expect(membership.containsName('room2'), isTrue);
    });

    test('returns all room names', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket2', 'room2');

      expect(manager.allRoomNames, containsAll(<String>['room1', 'room2']));
    });

    test('returns all rooms', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');

      final Iterable<RoomName> rooms = manager.allRooms;
      expect(rooms.length, equals(1));
      expect(rooms.first.value, equals('room1'));
    });

    test('clears all data', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');
      manager.joinByName('socket2', 'room2');

      manager.clear();
      expect(manager.roomCount, equals(0));
      expect(manager.socketCount, equals(0));
    });

    test('handles leaving non-existent room gracefully', () {
      final RoomManager manager = RoomManager();
      manager.leaveByName('socket1', 'room1'); // Should not throw
      expect(manager.roomCount, equals(0));
    });

    test('toString provides useful representation', () {
      final RoomManager manager = RoomManager();
      manager.joinByName('socket1', 'room1');

      final String str = manager.toString();
      expect(str, contains('RoomManager'));
      expect(str, contains('1 rooms'));
      expect(str, contains('1 sockets'));
    });
  });
}
