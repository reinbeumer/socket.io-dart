import 'package:test/test.dart';
import 'package:socket_io/src/models/event_data_models.dart';
import 'package:socket_io/src/value_objects/event_arguments_vo.dart';

void main() {
  group('EventArguments', () {
    group('factory constructors', () {
      test('creates from list', () {
        final List<Object?> list = <Object?>['hello', 42, true];
        final EventArguments args = EventArguments(list);

        expect(args.length, equals(3));
        expect(args[0], equals('hello'));
        expect(args[1], equals(42));
        expect(args[2], equals(true));
      });

      test('creates empty', () {
        final EventArguments args = EventArguments.empty();

        expect(args.isEmpty, isTrue);
        expect(args.length, equals(0));
      });

      test('creates single', () {
        final EventArguments args = EventArguments.single('test');

        expect(args.length, equals(1));
        expect(args[0], equals('test'));
      });

      test('creates multiple', () {
        final EventArguments args = EventArguments.multiple(<Object?>[1, 2, 3]);

        expect(args.length, equals(3));
        expect(args[0], equals(1));
      });

      test('creates from EventData', () {
        final List<EventData> eventDataList = <EventData>[
          StringEventData('hello'),
          NumericEventData(42),
          BooleanEventData(true),
        ];
        final EventArguments args = EventArguments.fromEventData(eventDataList);

        expect(args.length, equals(3));
        expect(args[0], equals('hello'));
        expect(args[1], equals(42));
        expect(args[2], equals(true));
      });

      test('creates immutable copy', () {
        final List<Object?> list = <Object?>['test'];
        final EventArguments args = EventArguments(list);

        // Modify original list
        list.add('new');

        // EventArguments should not be affected
        expect(args.length, equals(1));
      });
    });

    group('basic properties', () {
      test('length returns correct count', () {
        expect(EventArguments.empty().length, equals(0));
        expect(EventArguments(<Object?>['a']).length, equals(1));
        expect(EventArguments(<Object?>['a', 'b']).length, equals(2));
      });

      test('isEmpty returns correct value', () {
        expect(EventArguments.empty().isEmpty, isTrue);
        expect(EventArguments(<Object?>['a']).isEmpty, isFalse);
      });

      test('isNotEmpty returns correct value', () {
        expect(EventArguments.empty().isNotEmpty, isFalse);
        expect(EventArguments(<Object?>['a']).isNotEmpty, isTrue);
      });
    });

    group('indexer', () {
      test('returns value at valid index', () {
        final EventArguments args = EventArguments(<Object?>['a', 'b', 'c']);

        expect(args[0], equals('a'));
        expect(args[1], equals('b'));
        expect(args[2], equals('c'));
      });

      test('returns null for out of bounds index', () {
        final EventArguments args = EventArguments(<Object?>['a']);

        expect(args[-1], isNull);
        expect(args[1], isNull);
        expect(args[100], isNull);
      });
    });

    group('type-safe getters', () {
      late EventArguments args;

      setUp(() {
        args = EventArguments(<Object?>[
          'string',
          42,
          3.14,
          true,
          <String, dynamic>{'key': 'value'},
          <Object?>[1, 2, 3],
          null,
        ]);
      });

      test('getStringAt returns string', () {
        expect(args.getStringAt(0), equals('string'));
        expect(args.getStringAt(1), isNull); // Not a string
        expect(args.getStringAt(10), isNull); // Out of bounds
      });

      test('getIntAt returns int', () {
        expect(args.getIntAt(1), equals(42));
        expect(args.getIntAt(0), isNull); // Not an int
        expect(args.getIntAt(10), isNull); // Out of bounds
      });

      test('getIntAt converts num to int', () {
        final EventArguments numArgs = EventArguments(<Object?>[3.14]);
        expect(numArgs.getIntAt(0), equals(3));
      });

      test('getDoubleAt returns double', () {
        expect(args.getDoubleAt(2), equals(3.14));
        expect(args.getDoubleAt(0), isNull); // Not a number
        expect(args.getDoubleAt(10), isNull); // Out of bounds
      });

      test('getDoubleAt converts num to double', () {
        final EventArguments intArgs = EventArguments(<Object?>[42]);
        expect(intArgs.getDoubleAt(0), equals(42.0));
      });

      test('getBoolAt returns bool', () {
        expect(args.getBoolAt(3), equals(true));
        expect(args.getBoolAt(0), isNull); // Not a bool
        expect(args.getBoolAt(10), isNull); // Out of bounds
      });

      test('getMapAt returns map', () {
        final Map<String, dynamic>? map = args.getMapAt(4);
        expect(map, isNotNull);
        expect(map!['key'], equals('value'));
        expect(args.getMapAt(0), isNull); // Not a map
        expect(args.getMapAt(10), isNull); // Out of bounds
      });

      test('getMapAt converts generic map', () {
        final EventArguments mapArgs = EventArguments(<Object?>[
          <String, Object>{'test': 123},
        ]);
        final Map<String, dynamic>? map = mapArgs.getMapAt(0);
        expect(map, isNotNull);
        expect(map!['test'], equals(123));
      });

      test('getListAt returns list', () {
        final List<Object?>? list = args.getListAt(5);
        expect(list, isNotNull);
        expect(list!.length, equals(3));
        expect(args.getListAt(0), isNull); // Not a list
        expect(args.getListAt(10), isNull); // Out of bounds
      });

      test('getListAt converts generic list', () {
        final EventArguments listArgs = EventArguments(<Object?>[
          <int>[1, 2, 3],
        ]);
        final List<Object?>? list = listArgs.getListAt(0);
        expect(list, isNotNull);
        expect(list!.length, equals(3));
      });
    });

    group('conversion methods', () {
      test('toEventData converts all arguments', () {
        final EventArguments args = EventArguments(<Object?>['test', 42, true]);
        final List<EventData> eventData = args.toEventData();

        expect(eventData.length, equals(3));
        expect(eventData[0], isA<StringEventData>());
        expect(eventData[1], isA<NumericEventData>());
        expect(eventData[2], isA<BooleanEventData>());
      });

      test('toList returns mutable copy', () {
        final EventArguments args = EventArguments(<Object?>['test']);
        final List<Object?> list = args.toList();

        // Should be mutable
        list.add('new');
        expect(list.length, equals(2));

        // Original should not be affected
        expect(args.length, equals(1));
      });

      test('toJson returns list', () {
        final EventArguments args = EventArguments(<Object?>['test', 42]);
        final List<Object?> json = args.toJson();

        expect(json, equals(<Object?>['test', 42]));
      });
    });

    group('equality', () {
      test('equal arguments are equal', () {
        final EventArguments args1 = EventArguments(<Object?>['a', 1, true]);
        final EventArguments args2 = EventArguments(<Object?>['a', 1, true]);

        expect(args1, equals(args2));
        expect(args1.hashCode, equals(args2.hashCode));
      });

      test('different arguments are not equal', () {
        final EventArguments args1 = EventArguments(<Object?>['a', 1]);
        final EventArguments args2 = EventArguments(<Object?>['a', 2]);
        final EventArguments args3 = EventArguments(<Object?>['a']);

        expect(args1, isNot(equals(args2)));
        expect(args1, isNot(equals(args3)));
      });

      test('empty arguments are equal', () {
        final EventArguments args1 = EventArguments.empty();
        final EventArguments args2 = EventArguments.empty();

        expect(args1, equals(args2));
      });
    });

    group('toString', () {
      test('includes argument count', () {
        expect(EventArguments.empty().toString(), contains('0 args'));
        expect(EventArguments(<Object?>['a']).toString(), contains('1 args'));
        expect(EventArguments(<Object?>['a', 'b']).toString(), contains('2 args'));
      });
    });

    group('extension methods', () {
      late EventArguments args;

      setUp(() {
        args = EventArguments(<Object?>[1, 2, 3, 4, 5]);
      });

      test('map transforms arguments', () {
        final List<String> strings = args.map((final Object? o) => o.toString());
        expect(strings, equals(<String>['1', '2', '3', '4', '5']));
      });

      test('where filters arguments', () {
        final List<Object?> filtered = args.where((final Object? o) => o is int && o > 3);
        expect(filtered, equals(<int>[4, 5]));
      });

      test('firstOrNull returns first or null', () {
        expect(args.firstOrNull, equals(1));
        expect(EventArguments.empty().firstOrNull, isNull);
      });

      test('lastOrNull returns last or null', () {
        expect(args.lastOrNull, equals(5));
        expect(EventArguments.empty().lastOrNull, isNull);
      });

      test('every checks all arguments', () {
        expect(args.every((final Object? o) => o is int), isTrue);
        expect(args.every((final Object? o) => o is int && o as int > 3), isFalse);
      });

      test('any checks for any matching argument', () {
        expect(args.any((final Object? o) => o is int && o as int > 3), isTrue);
        expect(args.any((final Object? o) => o is String), isFalse);
      });

      test('take returns first n arguments', () {
        final EventArguments taken = args.take(3);
        expect(taken.length, equals(3));
        expect(taken[0], equals(1));
        expect(taken[2], equals(3));
      });

      test('skip skips first n arguments', () {
        final EventArguments skipped = args.skip(3);
        expect(skipped.length, equals(2));
        expect(skipped[0], equals(4));
        expect(skipped[1], equals(5));
      });
    });

    group('edge cases', () {
      test('handles null values', () {
        final EventArguments args = EventArguments(<Object?>[null, 'test', null]);

        expect(args.length, equals(3));
        expect(args[0], isNull);
        expect(args[1], equals('test'));
        expect(args[2], isNull);
      });

      test('handles mixed types', () {
        final EventArguments args = EventArguments(<Object?>[
          'string',
          42,
          3.14,
          true,
          <String, dynamic>{'key': 'value'},
          <Object?>[1, 2],
          null,
        ]);

        expect(args.length, equals(7));
        expect(args.getStringAt(0), equals('string'));
        expect(args.getIntAt(1), equals(42));
        expect(args.getDoubleAt(2), equals(3.14));
        expect(args.getBoolAt(3), equals(true));
        expect(args.getMapAt(4), isNotNull);
        expect(args.getListAt(5), isNotNull);
        expect(args[6], isNull);
      });

      test('handles nested structures', () {
        final EventArguments args = EventArguments(<Object?>[
          <String, dynamic>{
            'nested': <String, dynamic>{'deep': 'value'},
          },
          <Object?>[
            <Object?>[1, 2],
            <Object?>[3, 4],
          ],
        ]);

        final Map<String, dynamic>? map = args.getMapAt(0);
        expect(map, isNotNull);
        expect(map!['nested'], isA<Map>());

        final List<Object?>? list = args.getListAt(1);
        expect(list, isNotNull);
        expect(list!.length, equals(2));
        expect(list[0], isA<List>());
      });
    });
  });
}
