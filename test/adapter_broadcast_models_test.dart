import 'package:test/test.dart';
import 'package:socket_io/src/models/adapter_broadcast_models.dart';
import 'package:socket_io/src/models/socket_flags_models.dart';
import 'package:socket_io/src/value_objects/room_name_vo.dart';
import 'package:socket_io/src/value_objects/connection_id_vo.dart';

void main() {
  group('BroadcastOptions', () {
    group('Construction', () {
      test('creates with default values', () {
        final BroadcastOptions options = BroadcastOptions();

        expect(options.rooms, isEmpty);
        expect(options.except, isEmpty);
        expect(options.flags, equals(const SocketFlags()));
      });

      test('creates with specific values', () {
        final List<RoomName> rooms = <RoomName>[RoomName('room1'), RoomName('room2')];
        final List<ConnectionId> except = <ConnectionId>[ConnectionId('socket1')];
        final SocketFlags flags = SocketFlags(volatile: true);

        final BroadcastOptions options = BroadcastOptions(
          rooms: rooms,
          except: except,
          flags: flags,
        );

        expect(options.rooms, equals(rooms));
        expect(options.except, equals(except));
        expect(options.flags, equals(flags));
      });
    });

    group('fromMap', () {
      test('creates from legacy map format', () {
        final Map<String, dynamic> map = <String, dynamic>{
          'rooms': <dynamic>['room1', 'room2'],
          'except': <dynamic>['socket1', 'socket2'],
          'flags': <String, dynamic>{'volatile': true, 'compress': false},
        };

        final BroadcastOptions options = BroadcastOptions.fromMap(map);

        expect(options.rooms.length, equals(2));
        expect(options.rooms[0].value, equals('room1'));
        expect(options.rooms[1].value, equals('room2'));
        expect(options.except.length, equals(2));
        expect(options.except[0].value, equals('socket1'));
        expect(options.flags.volatile, isTrue);
        expect(options.flags.compress, isFalse);
      });

      test('handles empty map', () {
        final BroadcastOptions options = BroadcastOptions.fromMap(<String, dynamic>{});

        expect(options.rooms, isEmpty);
        expect(options.except, isEmpty);
        expect(options.flags, equals(const SocketFlags()));
      });

      test('handles null values in map', () {
        final Map<String, dynamic> map = <String, dynamic>{
          'rooms': null,
          'except': null,
          'flags': null,
        };

        final BroadcastOptions options = BroadcastOptions.fromMap(map);

        expect(options.rooms, isEmpty);
        expect(options.except, isEmpty);
        expect(options.flags, equals(const SocketFlags()));
      });
    });

    group('toMap', () {
      test('converts to legacy map format', () {
        final BroadcastOptions options = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
          except: <ConnectionId>[ConnectionId('socket1')],
          flags: SocketFlags(volatile: true),
        );

        final Map<String, dynamic> map = options.toMap();

        expect(map['rooms'], equals(<String>['room1']));
        expect(map['except'], equals(<String>['socket1']));
        expect(map['flags'], isA<Map<String, dynamic>>());
      });
    });

    group('copyWith', () {
      test('creates copy with modified rooms', () {
        final BroadcastOptions original = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
        );
        final List<RoomName> newRooms = <RoomName>[RoomName('room2')];

        final BroadcastOptions copy = original.copyWith(rooms: newRooms);

        expect(copy.rooms, equals(newRooms));
        expect(copy.except, equals(original.except));
        expect(copy.flags, equals(original.flags));
      });

      test('creates copy with modified except', () {
        final BroadcastOptions original = BroadcastOptions(
          except: <ConnectionId>[ConnectionId('socket1')],
        );
        final List<ConnectionId> newExcept = <ConnectionId>[ConnectionId('socket2')];

        final BroadcastOptions copy = original.copyWith(except: newExcept);

        expect(copy.rooms, equals(original.rooms));
        expect(copy.except, equals(newExcept));
        expect(copy.flags, equals(original.flags));
      });

      test('creates copy with modified flags', () {
        final BroadcastOptions original = BroadcastOptions(
          flags: SocketFlags(volatile: false),
        );
        final SocketFlags newFlags = SocketFlags(volatile: true);

        final BroadcastOptions copy = original.copyWith(flags: newFlags);

        expect(copy.rooms, equals(original.rooms));
        expect(copy.except, equals(original.except));
        expect(copy.flags, equals(newFlags));
      });
    });

    group('Fluent API', () {
      test('addRoom adds a single room', () {
        final BroadcastOptions original = BroadcastOptions();

        final BroadcastOptions modified = original.addRoom(RoomName('room1'));

        expect(modified.rooms.length, equals(1));
        expect(modified.rooms[0].value, equals('room1'));
      });

      test('addRooms adds multiple rooms', () {
        final BroadcastOptions original = BroadcastOptions();
        final List<RoomName> rooms = <RoomName>[RoomName('room1'), RoomName('room2')];

        final BroadcastOptions modified = original.addRooms(rooms);

        expect(modified.rooms.length, equals(2));
      });

      test('excludeSocket excludes a single socket', () {
        final BroadcastOptions original = BroadcastOptions();

        final BroadcastOptions modified = original.excludeSocket(ConnectionId('socket1'));

        expect(modified.except.length, equals(1));
        expect(modified.except[0].value, equals('socket1'));
      });

      test('excludeSockets excludes multiple sockets', () {
        final BroadcastOptions original = BroadcastOptions();
        final List<ConnectionId> sockets = <ConnectionId>[ConnectionId('socket1'), ConnectionId('socket2')];

        final BroadcastOptions modified = original.excludeSockets(sockets);

        expect(modified.except.length, equals(2));
      });

      test('withFlags sets flags', () {
        final BroadcastOptions original = BroadcastOptions();
        final SocketFlags flags = SocketFlags(volatile: true);

        final BroadcastOptions modified = original.withFlags(flags);

        expect(modified.flags.volatile, isTrue);
      });

      test('supports method chaining', () {
        final BroadcastOptions options = BroadcastOptions()
            .addRoom(RoomName('room1'))
            .excludeSocket(ConnectionId('socket1'))
            .withFlags(SocketFlags(volatile: true));

        expect(options.rooms.length, equals(1));
        expect(options.except.length, equals(1));
        expect(options.flags.volatile, isTrue);
      });
    });

    group('Query methods', () {
      test('hasRoomFilter returns true when rooms specified', () {
        final BroadcastOptions options = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
        );

        expect(options.hasRoomFilter, isTrue);
      });

      test('hasRoomFilter returns false when no rooms', () {
        final BroadcastOptions options = BroadcastOptions();

        expect(options.hasRoomFilter, isFalse);
      });

      test('hasExclusions returns true when sockets excluded', () {
        final BroadcastOptions options = BroadcastOptions(
          except: <ConnectionId>[ConnectionId('socket1')],
        );

        expect(options.hasExclusions, isTrue);
      });

      test('hasExclusions returns false when no exclusions', () {
        final BroadcastOptions options = BroadcastOptions();

        expect(options.hasExclusions, isFalse);
      });

      test('isExcluded checks if socket is excluded', () {
        final ConnectionId socket1 = ConnectionId('socket1');
        final ConnectionId socket2 = ConnectionId('socket2');
        final BroadcastOptions options = BroadcastOptions(
          except: <ConnectionId>[socket1],
        );

        expect(options.isExcluded(socket1), isTrue);
        expect(options.isExcluded(socket2), isFalse);
      });

      test('broadcastToAll returns true when no rooms specified', () {
        final BroadcastOptions options = BroadcastOptions();

        expect(options.broadcastToAll, isTrue);
      });

      test('broadcastToAll returns false when rooms specified', () {
        final BroadcastOptions options = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
        );

        expect(options.broadcastToAll, isFalse);
      });
    });

    group('Equality', () {
      test('equal instances are equal', () {
        final BroadcastOptions options1 = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
          except: <ConnectionId>[ConnectionId('socket1')],
          flags: SocketFlags(volatile: true),
        );
        final BroadcastOptions options2 = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
          except: <ConnectionId>[ConnectionId('socket1')],
          flags: SocketFlags(volatile: true),
        );

        expect(options1, equals(options2));
        expect(options1.hashCode, equals(options2.hashCode));
      });

      test('different instances are not equal', () {
        final BroadcastOptions options1 = BroadcastOptions(
          rooms: <RoomName>[RoomName('room1')],
        );
        final BroadcastOptions options2 = BroadcastOptions(
          rooms: <RoomName>[RoomName('room2')],
        );

        expect(options1, isNot(equals(options2)));
      });
    });

    test('toString returns readable representation', () {
      final BroadcastOptions options = BroadcastOptions(
        rooms: <RoomName>[RoomName('room1')],
        except: <ConnectionId>[ConnectionId('socket1')],
      );

      final String str = options.toString();
      expect(str, contains('BroadcastOptions'));
      expect(str, contains('room1'));
      expect(str, contains('socket1'));
    });
  });

  group('RoomFilter', () {
    group('Construction', () {
      test('creates with default values', () {
        final RoomFilter filter = RoomFilter();

        expect(filter.includeRooms, isEmpty);
        expect(filter.excludeRooms, isEmpty);
        expect(filter.namePattern, isNull);
      });

      test('creates with include rooms', () {
        final List<RoomName> rooms = <RoomName>[RoomName('room1')];
        final RoomFilter filter = RoomFilter(includeRooms: rooms);

        expect(filter.includeRooms, equals(rooms));
      });

      test('creates with exclude rooms', () {
        final List<RoomName> rooms = <RoomName>[RoomName('room1')];
        final RoomFilter filter = RoomFilter(excludeRooms: rooms);

        expect(filter.excludeRooms, equals(rooms));
      });

      test('creates with name pattern', () {
        final RoomFilter filter = RoomFilter(namePattern: 'game.*');

        expect(filter.namePattern, equals('game.*'));
      });
    });

    group('Factory constructors', () {
      test('include creates filter with inclusions', () {
        final List<RoomName> rooms = <RoomName>[RoomName('room1')];
        final RoomFilter filter = RoomFilter.include(rooms);

        expect(filter.includeRooms, equals(rooms));
        expect(filter.excludeRooms, isEmpty);
      });

      test('exclude creates filter with exclusions', () {
        final List<RoomName> rooms = <RoomName>[RoomName('room1')];
        final RoomFilter filter = RoomFilter.exclude(rooms);

        expect(filter.excludeRooms, equals(rooms));
        expect(filter.includeRooms, isEmpty);
      });

      test('pattern creates filter with pattern', () {
        final RoomFilter filter = RoomFilter.pattern('game.*');

        expect(filter.namePattern, equals('game.*'));
      });
    });

    group('matches', () {
      test('matches all when filter is empty', () {
        final RoomFilter filter = RoomFilter();
        final RoomName room = RoomName('any-room');

        expect(filter.matches(room), isTrue);
      });

      test('matches only included rooms', () {
        final RoomName room1 = RoomName('room1');
        final RoomName room2 = RoomName('room2');
        final RoomFilter filter = RoomFilter(includeRooms: <RoomName>[room1]);

        expect(filter.matches(room1), isTrue);
        expect(filter.matches(room2), isFalse);
      });

      test('excludes excluded rooms', () {
        final RoomName room1 = RoomName('room1');
        final RoomName room2 = RoomName('room2');
        final RoomFilter filter = RoomFilter(excludeRooms: <RoomName>[room1]);

        expect(filter.matches(room1), isFalse);
        expect(filter.matches(room2), isTrue);
      });

      test('matches name pattern', () {
        final RoomFilter filter = RoomFilter(namePattern: r'^game\d+$');
        final RoomName match = RoomName('game123');
        final RoomName noMatch = RoomName('room456');

        expect(filter.matches(match), isTrue);
        expect(filter.matches(noMatch), isFalse);
      });

      test('combines include and exclude', () {
        final RoomName room1 = RoomName('room1');
        final RoomName room2 = RoomName('room2');
        final RoomName room3 = RoomName('room3');
        final RoomFilter filter = RoomFilter(
          includeRooms: <RoomName>[room1, room2],
          excludeRooms: <RoomName>[room2],
        );

        expect(filter.matches(room1), isTrue);
        expect(filter.matches(room2), isFalse); // excluded even though included
        expect(filter.matches(room3), isFalse);
      });
    });

    group('filter', () {
      test('filters list of rooms', () {
        final RoomName room1 = RoomName('game1');
        final RoomName room2 = RoomName('game2');
        final RoomName room3 = RoomName('chat1');
        final List<RoomName> rooms = <RoomName>[room1, room2, room3];
        final RoomFilter filter = RoomFilter(namePattern: r'^game');

        final List<RoomName> filtered = filter.filter(rooms);

        expect(filtered.length, equals(2));
        expect(filtered, contains(room1));
        expect(filtered, contains(room2));
        expect(filtered, isNot(contains(room3)));
      });
    });

    group('Equality', () {
      test('equal instances are equal', () {
        final RoomFilter filter1 = RoomFilter(
          includeRooms: <RoomName>[RoomName('room1')],
          namePattern: 'game.*',
        );
        final RoomFilter filter2 = RoomFilter(
          includeRooms: <RoomName>[RoomName('room1')],
          namePattern: 'game.*',
        );

        expect(filter1, equals(filter2));
        expect(filter1.hashCode, equals(filter2.hashCode));
      });

      test('different instances are not equal', () {
        final RoomFilter filter1 = RoomFilter(namePattern: 'game.*');
        final RoomFilter filter2 = RoomFilter(namePattern: 'chat.*');

        expect(filter1, isNot(equals(filter2)));
      });
    });

    test('toString returns readable representation', () {
      final RoomFilter filter = RoomFilter(
        includeRooms: <RoomName>[RoomName('room1')],
        namePattern: 'game.*',
      );

      final String str = filter.toString();
      expect(str, contains('RoomFilter'));
      expect(str, contains('room1'));
      expect(str, contains('game.*'));
    });
  });
}
