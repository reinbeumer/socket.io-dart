import 'package:test/test.dart';
import 'package:socket_io/src/models/transport_data_models.dart';

void main() {
  group('TransportData', () {
    group('StringTransportData', () {
      test('creates and accesses string value', () {
        final StringTransportData data = StringTransportData('hello');
        expect(data.value, equals('hello'));
        expect(data.toRaw(), equals('hello'));
      });

      test('equality works correctly', () {
        final StringTransportData data1 = StringTransportData('hello');
        final StringTransportData data2 = StringTransportData('hello');
        final StringTransportData data3 = StringTransportData('world');

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('hashCode works correctly', () {
        final StringTransportData data1 = StringTransportData('hello');
        final StringTransportData data2 = StringTransportData('hello');

        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('toString provides useful representation', () {
        final StringTransportData data = StringTransportData('test');
        expect(data.toString(), contains('StringTransportData'));
        expect(data.toString(), contains('test'));
      });
    });

    group('BinaryTransportData', () {
      test('creates and accesses binary data', () {
        final BinaryTransportData data = BinaryTransportData(<int>[1, 2, 3]);
        expect(data.bytes, equals(<int>[1, 2, 3]));
        expect(data.toRaw(), equals(<int>[1, 2, 3]));
      });

      test('fromList factory creates from dynamic list', () {
        final BinaryTransportData data = BinaryTransportData.fromList(<dynamic>[
          1,
          2,
          <int>[3, 4]
        ]);
        expect(data.bytes, equals(<int>[1, 2, 3, 4]));
      });

      test('toRaw returns immutable list', () {
        final BinaryTransportData data = BinaryTransportData(<int>[1, 2, 3]);
        final List<int> raw = data.toRaw();
        expect(() => raw.add(4), throwsUnsupportedError);
      });

      test('equality works correctly', () {
        final BinaryTransportData data1 = BinaryTransportData(<int>[1, 2, 3]);
        final BinaryTransportData data2 = BinaryTransportData(<int>[1, 2, 3]);
        final BinaryTransportData data3 = BinaryTransportData(<int>[1, 2, 4]);

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('toString provides useful representation', () {
        final BinaryTransportData data = BinaryTransportData(<int>[1, 2, 3]);
        expect(data.toString(), contains('BinaryTransportData'));
        expect(data.toString(), contains('3 bytes'));
      });
    });

    group('JsonTransportData', () {
      test('creates and accesses json data', () {
        final JsonTransportData data = JsonTransportData(<String, dynamic>{'key': 'value'});
        expect(data.data, equals(<String, dynamic>{'key': 'value'}));
        expect(data.toRaw(), equals(<String, dynamic>{'key': 'value'}));
      });

      test('toRaw returns immutable map', () {
        final JsonTransportData data = JsonTransportData(<String, dynamic>{'key': 'value'});
        final Map<String, dynamic> raw = data.toRaw();
        expect(() => raw['new'] = 'value', throwsUnsupportedError);
      });

      test('equality works correctly', () {
        final JsonTransportData data1 = JsonTransportData(<String, dynamic>{'key': 'value'});
        final JsonTransportData data2 = JsonTransportData(<String, dynamic>{'key': 'value'});
        final JsonTransportData data3 = JsonTransportData(<String, dynamic>{'key': 'other'});

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('toString provides useful representation', () {
        final JsonTransportData data = JsonTransportData(<String, dynamic>{'key': 'value'});
        expect(data.toString(), contains('JsonTransportData'));
      });
    });

    group('ListTransportData', () {
      test('creates and accesses list data', () {
        final ListTransportData data = ListTransportData(<Object?>[1, 'two', 3.0]);
        expect(data.items, equals(<Object?>[1, 'two', 3.0]));
        expect(data.toRaw(), equals(<Object?>[1, 'two', 3.0]));
      });

      test('toRaw returns immutable list', () {
        final ListTransportData data = ListTransportData(<Object?>[1, 2, 3]);
        final List<Object?> raw = data.toRaw();
        expect(() => raw.add(4), throwsUnsupportedError);
      });

      test('equality works correctly', () {
        final ListTransportData data1 = ListTransportData(<Object?>[1, 2, 3]);
        final ListTransportData data2 = ListTransportData(<Object?>[1, 2, 3]);
        final ListTransportData data3 = ListTransportData(<Object?>[1, 2, 4]);

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('toString provides useful representation', () {
        final ListTransportData data = ListTransportData(<Object?>[1, 2, 3]);
        expect(data.toString(), contains('ListTransportData'));
      });
    });

    group('MixedTransportData', () {
      test('creates and accesses mixed data', () {
        final MixedTransportData data = MixedTransportData(42);
        expect(data.value, equals(42));
        expect(data.toRaw(), equals(42));
      });

      test('accepts any object type', () {
        final MixedTransportData stringData = MixedTransportData('test');
        final MixedTransportData numData = MixedTransportData(42);
        final MixedTransportData boolData = MixedTransportData(true);

        expect(stringData.value, equals('test'));
        expect(numData.value, equals(42));
        expect(boolData.value, equals(true));
      });

      test('equality works correctly', () {
        final MixedTransportData data1 = MixedTransportData(42);
        final MixedTransportData data2 = MixedTransportData(42);
        final MixedTransportData data3 = MixedTransportData(43);

        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('toString provides useful representation', () {
        final MixedTransportData data = MixedTransportData(42);
        expect(data.toString(), contains('MixedTransportData'));
        expect(data.toString(), contains('42'));
      });
    });

    group('ObjectToTransportData extension', () {
      test('converts String to StringTransportData', () {
        final TransportData data = 'hello'.toTransportData();
        expect(data, isA<StringTransportData>());
        expect((data as StringTransportData).value, equals('hello'));
      });

      test('converts List<int> to BinaryTransportData', () {
        final TransportData data = <int>[1, 2, 3].toTransportData();
        expect(data, isA<BinaryTransportData>());
        expect((data as BinaryTransportData).bytes, equals(<int>[1, 2, 3]));
      });

      test('converts Map<String, dynamic> to JsonTransportData', () {
        final TransportData data = <String, dynamic>{'key': 'value'}.toTransportData();
        expect(data, isA<JsonTransportData>());
        expect((data as JsonTransportData).data, equals(<String, dynamic>{'key': 'value'}));
      });

      test('converts List<Object?> to ListTransportData', () {
        final TransportData data = <Object?>[1, 'two', 3.0].toTransportData();
        expect(data, isA<ListTransportData>());
        expect((data as ListTransportData).items, equals(<Object?>[1, 'two', 3.0]));
      });

      test('converts other types to MixedTransportData', () {
        final TransportData data = 42.toTransportData();
        expect(data, isA<MixedTransportData>());
        expect((data as MixedTransportData).value, equals(42));
      });
    });

    group('TransportDataToObject extension', () {
      test('converts StringTransportData to String', () {
        final TransportData data = StringTransportData('hello');
        final Object obj = data.toObject();
        expect(obj, equals('hello'));
      });

      test('converts BinaryTransportData to List<int>', () {
        final TransportData data = BinaryTransportData(<int>[1, 2, 3]);
        final Object obj = data.toObject();
        expect(obj, equals(<int>[1, 2, 3]));
      });

      test('converts JsonTransportData to Map', () {
        final TransportData data = JsonTransportData(<String, dynamic>{'key': 'value'});
        final Object obj = data.toObject();
        expect(obj, equals(<String, dynamic>{'key': 'value'}));
      });

      test('converts ListTransportData to List', () {
        final TransportData data = ListTransportData(<Object?>[1, 2, 3]);
        final Object obj = data.toObject();
        expect(obj, equals(<Object?>[1, 2, 3]));
      });

      test('converts MixedTransportData to original type', () {
        final TransportData data = MixedTransportData(42);
        final Object obj = data.toObject();
        expect(obj, equals(42));
      });
    });

    group('Type safety', () {
      test('abstract class supports type checking', () {
        // Test that we can check types using is operator
        final TransportData data = StringTransportData('test');
        String result;
        if (data is StringTransportData) {
          result = 'string';
        } else if (data is BinaryTransportData) {
          result = 'binary';
        } else if (data is JsonTransportData) {
          result = 'json';
        } else if (data is ListTransportData) {
          result = 'list';
        } else if (data is MixedTransportData) {
          result = 'mixed';
        } else {
          result = 'unknown';
        }
        expect(result, equals('string'));
      });

      test('type checking works with all types', () {
        final List<TransportData> dataList = <TransportData>[
          StringTransportData('test'),
          BinaryTransportData(<int>[1, 2, 3]),
          JsonTransportData(<String, dynamic>{'key': 'value'}),
          ListTransportData(<Object?>[1, 2, 3]),
          MixedTransportData(42),
        ];

        final List<String> types = dataList.map((final TransportData data) {
          if (data is StringTransportData) {
            return 'string';
          } else if (data is BinaryTransportData) {
            return 'binary';
          } else if (data is JsonTransportData) {
            return 'json';
          } else if (data is ListTransportData) {
            return 'list';
          } else if (data is MixedTransportData) {
            return 'mixed';
          } else {
            return 'unknown';
          }
        }).toList();

        expect(types, equals(<String>['string', 'binary', 'json', 'list', 'mixed']));
      });
    });
  });
}
