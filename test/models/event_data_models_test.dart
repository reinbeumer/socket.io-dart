import 'package:test/test.dart';
import 'package:socket_io/src/models/event_data_models.dart';

void main() {
  group('EventData', () {
    group('StringEventData', () {
      test('creates and accesses string value', () {
        const StringEventData data = StringEventData('hello');
        expect(data.value, equals('hello'));
        expect(data.toString(), equals('hello'));
      });

      test('equality works correctly', () {
        const StringEventData data1 = StringEventData('same');
        const StringEventData data2 = StringEventData('same');
        const StringEventData data3 = StringEventData('different');

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });
    });

    group('NumericEventData', () {
      test('creates and accesses numeric value', () {
        const NumericEventData data = NumericEventData(42);
        expect(data.value, equals(42));
      });

      test('works with decimals', () {
        const NumericEventData data = NumericEventData(3.14);
        expect(data.value, equals(3.14));
      });
    });

    group('BooleanEventData', () {
      test('creates and accesses boolean value', () {
        const BooleanEventData data = BooleanEventData(true);
        expect(data.value, isTrue);
      });
    });

    group('MapEventData', () {
      test('creates and accesses map value', () {
        const MapEventData data = MapEventData(<String, Object?>{'key': 'value'});
        expect(data.value, equals(<String, Object?>{'key': 'value'}));
      });

      test('equality works correctly', () {
        const MapEventData data1 = MapEventData(<String, Object?>{'a': 1});
        const MapEventData data2 = MapEventData(<String, Object?>{'a': 1});
        const MapEventData data3 = MapEventData(<String, Object?>{'a': 2});

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });
    });

    group('ListEventData', () {
      test('creates and accesses list value', () {
        const ListEventData data = ListEventData(<Object?>[1, 'two', 3]);
        expect(data.value, equals(<Object?>[1, 'two', 3]));
      });

      test('equality works correctly', () {
        const ListEventData data1 = ListEventData(<Object?>[1, 2]);
        const ListEventData data2 = ListEventData(<Object?>[1, 2]);
        const ListEventData data3 = ListEventData(<Object?>[1, 3]);

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });
    });

    group('NullEventData', () {
      test('represents null', () {
        const NullEventData data = NullEventData();
        expect(data.toString(), equals('null'));
      });

      test('all instances are equal', () {
        const NullEventData data1 = NullEventData();
        const NullEventData data2 = NullEventData();
        expect(data1, equals(data2));
      });
    });

    group('ObjectEventData', () {
      test('wraps generic objects', () {
        final Object obj = Object();
        final ObjectEventData data = ObjectEventData(obj);
        expect(data.value, same(obj));
      });
    });

    group('EventDataConversion', () {
      test('converts string to StringEventData', () {
        final EventData data = 'hello'.toEventData();
        expect(data, isA<StringEventData>());
        expect((data as StringEventData).value, equals('hello'));
      });

      test('converts num to NumericEventData', () {
        final EventData data = 42.toEventData();
        expect(data, isA<NumericEventData>());
        expect((data as NumericEventData).value, equals(42));
      });

      test('converts bool to BooleanEventData', () {
        final EventData data = true.toEventData();
        expect(data, isA<BooleanEventData>());
        expect((data as BooleanEventData).value, isTrue);
      });

      test('converts Map to MapEventData', () {
        final EventData data = <String, Object?>{'key': 'value'}.toEventData();
        expect(data, isA<MapEventData>());
        expect((data as MapEventData).value, equals(<String, Object?>{'key': 'value'}));
      });

      test('converts List to ListEventData', () {
        final EventData data = <Object?>[1, 2, 3].toEventData();
        expect(data, isA<ListEventData>());
        expect((data as ListEventData).value, equals(<Object?>[1, 2, 3]));
      });

      test('converts null to NullEventData', () {
        final EventData data = null.toEventData();
        expect(data, isA<NullEventData>());
      });

      test('converts generic objects to ObjectEventData', () {
        final Object obj = Object();
        final EventData data = obj.toEventData();
        expect(data, isA<ObjectEventData>());
        expect((data as ObjectEventData).value, same(obj));
      });
    });

    group('Pattern matching behavior', () {
      test('type checking works with if-else', () {
        const EventData data = StringEventData('test');

        String result;
        if (data is StringEventData) {
          result = 'string: ${data.value}';
        } else if (data is NumericEventData) {
          result = 'num: ${data.value}';
        } else if (data is BooleanEventData) {
          result = 'bool: ${data.value}';
        } else if (data is MapEventData) {
          result = 'map: ${data.value.length}';
        } else if (data is ListEventData) {
          result = 'list: ${data.value.length}';
        } else if (data is NullEventData) {
          result = 'null';
        } else if (data is ObjectEventData) {
          result = 'object: ${data.value.runtimeType}';
        } else {
          result = 'unknown';
        }

        expect(result, equals('string: test'));
      });
    });
  });
}
