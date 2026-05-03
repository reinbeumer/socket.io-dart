import 'package:test/test.dart';
import 'package:socket_io/src/models/socket_data_models.dart';

void main() {
  group('SocketDataModel', () {
    test('creates empty model', () {
      final SocketDataModel data = SocketDataModel();
      expect(data.isEmpty, isTrue);
      expect(data.length, equals(0));
    });

    test('creates from map', () {
      final SocketDataModel data = SocketDataModel.fromMap(<String, Object?>{
        'name': 'test',
        'count': 42,
      });
      expect(data.length, equals(2));
      expect(data['name'], equals('test'));
      expect(data['count'], equals(42));
    });

    test('stores and retrieves values', () {
      final SocketDataModel data = SocketDataModel();
      data['key'] = 'value';
      expect(data['key'], equals('value'));
    });

    test('getString returns string or null', () {
      final SocketDataModel data = SocketDataModel();
      data['text'] = 'hello';
      data['number'] = 42;

      expect(data.getString('text'), equals('hello'));
      expect(data.getString('number'), isNull);
      expect(data.getString('missing'), isNull);
    });

    test('getInt returns int or null', () {
      final SocketDataModel data = SocketDataModel();
      data['count'] = 42;
      data['text'] = 'hello';

      expect(data.getInt('count'), equals(42));
      expect(data.getInt('text'), isNull);
      expect(data.getInt('missing'), isNull);
    });

    test('getBool returns bool or null', () {
      final SocketDataModel data = SocketDataModel();
      data['flag'] = true;
      data['text'] = 'hello';

      expect(data.getBool('flag'), isTrue);
      expect(data.getBool('text'), isNull);
      expect(data.getBool('missing'), isNull);
    });

    test('getDouble returns double or null', () {
      final SocketDataModel data = SocketDataModel();
      data['value'] = 3.14;
      data['text'] = 'hello';

      expect(data.getDouble('value'), equals(3.14));
      expect(data.getDouble('text'), isNull);
      expect(data.getDouble('missing'), isNull);
    });

    test('getMap returns map or null', () {
      final SocketDataModel data = SocketDataModel();
      data['obj'] = <String, Object?>{'nested': 'value'};
      data['text'] = 'hello';

      expect(data.getMap('obj'), equals(<String, Object?>{'nested': 'value'}));
      expect(data.getMap('text'), isNull);
      expect(data.getMap('missing'), isNull);
    });

    test('getList returns list or null', () {
      final SocketDataModel data = SocketDataModel();
      data['arr'] = <Object?>[1, 2, 3];
      data['text'] = 'hello';

      expect(data.getList('arr'), equals(<Object?>[1, 2, 3]));
      expect(data.getList('text'), isNull);
      expect(data.getList('missing'), isNull);
    });

    test('containsKey checks existence', () {
      final SocketDataModel data = SocketDataModel();
      data['exists'] = 'value';

      expect(data.containsKey('exists'), isTrue);
      expect(data.containsKey('missing'), isFalse);
    });

    test('remove removes key', () {
      final SocketDataModel data = SocketDataModel();
      data['key'] = 'value';

      final Object? removed = data.remove('key');
      expect(removed, equals('value'));
      expect(data.containsKey('key'), isFalse);
    });

    test('clear removes all data', () {
      final SocketDataModel data = SocketDataModel();
      data['a'] = 1;
      data['b'] = 2;
      expect(data.length, equals(2));

      data.clear();
      expect(data.isEmpty, isTrue);
      expect(data.length, equals(0));
    });

    test('keys returns all keys', () {
      final SocketDataModel data = SocketDataModel();
      data['a'] = 1;
      data['b'] = 2;

      expect(data.keys, containsAll(<String>['a', 'b']));
    });

    test('values returns all values', () {
      final SocketDataModel data = SocketDataModel();
      data['a'] = 1;
      data['b'] = 2;

      expect(data.values, containsAll(<int>[1, 2]));
    });

    test('isNotEmpty works correctly', () {
      final SocketDataModel data = SocketDataModel();
      expect(data.isNotEmpty, isFalse);

      data['key'] = 'value';
      expect(data.isNotEmpty, isTrue);
    });

    test('toMap creates plain map', () {
      final SocketDataModel data = SocketDataModel();
      data['a'] = 1;
      data['b'] = 'two';

      final Map<String, Object?> map = data.toMap();
      expect(map, equals(<String, Object?>{'a': 1, 'b': 'two'}));
      expect(map, isNot(same(data.toMap()))); // Different instances
    });

    test('copy creates independent copy', () {
      final SocketDataModel original = SocketDataModel();
      original['key'] = 'value';

      final SocketDataModel copy = original.copy();
      expect(copy['key'], equals('value'));

      copy['key'] = 'modified';
      expect(original['key'], equals('value')); // Original unchanged
    });

    test('toString provides useful representation', () {
      final SocketDataModel data = SocketDataModel();
      data['test'] = 'value';

      final String str = data.toString();
      expect(str, contains('SocketDataModel'));
      expect(str, contains('test'));
      expect(str, contains('value'));
    });
  });
}
