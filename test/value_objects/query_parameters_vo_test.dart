import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/query_parameters_vo.dart';

void main() {
  group('QueryParameters', () {
    group('constructor', () {
      test('creates from map with string values', () {
        final Map<String, dynamic> params = {'token': 'abc123', 'room': 'chat'};
        final QueryParameters query = QueryParameters(params);

        expect(query.get('token'), 'abc123');
        expect(query.get('room'), 'chat');
        expect(query.length, 2);
      });

      test('creates from map with non-string values', () {
        final Map<String, dynamic> params = {
          'id': 123,
          'active': true,
          'ratio': 1.5,
        };
        final QueryParameters query = QueryParameters(params);

        expect(query.get('id'), '123');
        expect(query.get('active'), 'true');
        expect(query.get('ratio'), '1.5');
      });

      test('throws on null values', () {
        final Map<String, dynamic> params = {'token': null};

        expect(
          () => QueryParameters(params),
          throwsArgumentError,
        );
      });

      test('creates empty query parameters', () {
        final QueryParameters query = QueryParameters.empty();

        expect(query.isEmpty, true);
        expect(query.length, 0);
      });
    });

    group('fromQueryString', () {
      test('parses simple query string', () {
        final QueryParameters query = QueryParameters.fromQueryString('token=abc&room=chat');

        expect(query.get('token'), 'abc');
        expect(query.get('room'), 'chat');
        expect(query.length, 2);
      });

      test('parses query string with leading question mark', () {
        final QueryParameters query = QueryParameters.fromQueryString('?token=abc&room=chat');

        expect(query.get('token'), 'abc');
        expect(query.get('room'), 'chat');
      });

      test('parses query string with encoded values', () {
        final QueryParameters query = QueryParameters.fromQueryString('name=John%20Doe&email=test%40example.com');

        expect(query.get('name'), 'John Doe');
        expect(query.get('email'), 'test@example.com');
      });

      test('handles empty values', () {
        final QueryParameters query = QueryParameters.fromQueryString('token=&room=chat');

        expect(query.get('token'), '');
        expect(query.get('room'), 'chat');
      });

      test('handles empty string', () {
        final QueryParameters query = QueryParameters.fromQueryString('');

        expect(query.isEmpty, true);
      });

      test('handles malformed query strings', () {
        final QueryParameters query = QueryParameters.fromQueryString('token&room=chat&');

        expect(query.get('token'), '');
        expect(query.get('room'), 'chat');
      });
    });

    group('get and access methods', () {
      late QueryParameters query;

      setUp(() {
        query = QueryParameters({
          'token': 'abc123',
          'room': 'chat',
          'count': '5',
        });
      });

      test('get returns value for existing key', () {
        expect(query.get('token'), 'abc123');
      });

      test('get returns null for non-existing key', () {
        expect(query.get('missing'), null);
      });

      test('getOrDefault returns value for existing key', () {
        expect(query.getOrDefault('token', 'default'), 'abc123');
      });

      test('getOrDefault returns default for non-existing key', () {
        expect(query.getOrDefault('missing', 'default'), 'default');
      });

      test('has returns true for existing key', () {
        expect(query.has('token'), true);
      });

      test('has returns false for non-existing key', () {
        expect(query.has('missing'), false);
      });

      test('keys returns all keys', () {
        expect(query.keys, containsAll(['token', 'room', 'count']));
        expect(query.keys.length, 3);
      });

      test('values returns all values', () {
        expect(query.values, containsAll(['abc123', 'chat', '5']));
        expect(query.values.length, 3);
      });

      test('entries returns all entries', () {
        final List<MapEntry<String, String>> entries = query.entries.toList();
        expect(entries.length, 3);
      });

      test('length returns number of parameters', () {
        expect(query.length, 3);
      });

      test('isEmpty returns false for non-empty', () {
        expect(query.isEmpty, false);
      });

      test('isNotEmpty returns true for non-empty', () {
        expect(query.isNotEmpty, true);
      });

      test('isEmpty returns true for empty', () {
        final QueryParameters empty = QueryParameters.empty();
        expect(empty.isEmpty, true);
        expect(empty.isNotEmpty, false);
      });
    });

    group('conversion methods', () {
      late QueryParameters query;

      setUp(() {
        query = QueryParameters({'token': 'abc123', 'room': 'chat'});
      });

      test('toMap returns Map<String, String>', () {
        final Map<String, String> map = query.toMap();

        expect(map, isA<Map<String, String>>());
        expect(map['token'], 'abc123');
        expect(map['room'], 'chat');
      });

      test('toDynamicMap returns Map<String, dynamic>', () {
        final Map<String, dynamic> map = query.toDynamicMap();

        expect(map, isA<Map<String, dynamic>>());
        expect(map['token'], 'abc123');
        expect(map['room'], 'chat');
      });

      test('toQueryString returns formatted string', () {
        final String queryString = query.toQueryString();

        expect(
          queryString,
          anyOf('token=abc123&room=chat', 'room=chat&token=abc123'),
        );
      });

      test('toQueryString encodes special characters', () {
        final QueryParameters special = QueryParameters({
          'name': 'John Doe',
          'email': 'test@example.com',
        });

        final String queryString = special.toQueryString();

        expect(queryString, contains('John%20Doe'));
        expect(queryString, contains('test%40example.com'));
      });

      test('toQueryString returns empty string for empty parameters', () {
        final QueryParameters empty = QueryParameters.empty();
        expect(empty.toQueryString(), '');
      });
    });

    group('immutability methods', () {
      late QueryParameters query;

      setUp(() {
        query = QueryParameters({'token': 'abc123', 'room': 'chat'});
      });

      test('withParameter adds new parameter', () {
        final QueryParameters newQuery = query.withParameter('user', 'john');

        expect(newQuery.get('user'), 'john');
        expect(newQuery.get('token'), 'abc123');
        expect(newQuery.length, 3);

        // Original unchanged
        expect(query.has('user'), false);
        expect(query.length, 2);
      });

      test('withParameter replaces existing parameter', () {
        final QueryParameters newQuery = query.withParameter('token', 'xyz789');

        expect(newQuery.get('token'), 'xyz789');
        expect(newQuery.length, 2);

        // Original unchanged
        expect(query.get('token'), 'abc123');
      });

      test('withoutParameter removes parameter', () {
        final QueryParameters newQuery = query.withoutParameter('token');

        expect(newQuery.has('token'), false);
        expect(newQuery.get('room'), 'chat');
        expect(newQuery.length, 1);

        // Original unchanged
        expect(query.has('token'), true);
        expect(query.length, 2);
      });

      test('withoutParameter on non-existing key', () {
        final QueryParameters newQuery = query.withoutParameter('missing');

        expect(newQuery.length, 2);
      });

      test('merge combines two query parameters', () {
        final QueryParameters other = QueryParameters({'user': 'john', 'id': '1'});
        final QueryParameters merged = query.merge(other);

        expect(merged.get('token'), 'abc123');
        expect(merged.get('room'), 'chat');
        expect(merged.get('user'), 'john');
        expect(merged.get('id'), '1');
        expect(merged.length, 4);
      });

      test('merge overwrites with other values on conflict', () {
        final QueryParameters other = QueryParameters({'token': 'xyz789', 'user': 'john'});
        final QueryParameters merged = query.merge(other);

        expect(merged.get('token'), 'xyz789'); // Overwritten
        expect(merged.get('user'), 'john');
        expect(merged.length, 3);

        // Original unchanged
        expect(query.get('token'), 'abc123');
      });
    });

    group('equality and hashCode', () {
      test('equal query parameters are equal', () {
        final QueryParameters query1 = QueryParameters({'token': 'abc', 'room': 'chat'});
        final QueryParameters query2 = QueryParameters({'token': 'abc', 'room': 'chat'});

        expect(query1, equals(query2));
        expect(query1.hashCode, equals(query2.hashCode));
      });

      test('different query parameters are not equal', () {
        final QueryParameters query1 = QueryParameters({'token': 'abc'});
        final QueryParameters query2 = QueryParameters({'token': 'xyz'});

        expect(query1, isNot(equals(query2)));
      });

      test('query parameters with different keys are not equal', () {
        final QueryParameters query1 = QueryParameters({'token': 'abc'});
        final QueryParameters query2 = QueryParameters({'key': 'abc'});

        expect(query1, isNot(equals(query2)));
      });

      test('identical instances are equal', () {
        final QueryParameters query = QueryParameters({'token': 'abc'});

        expect(query, equals(query));
      });

      test('empty query parameters are equal', () {
        final QueryParameters query1 = QueryParameters.empty();
        final QueryParameters query2 = QueryParameters({});

        expect(query1, equals(query2));
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        final QueryParameters query = QueryParameters({'token': 'abc', 'room': 'chat'});

        final String str = query.toString();

        expect(str, startsWith('QueryParameters('));
        expect(str, endsWith(')'));
      });

      test('returns empty for empty parameters', () {
        final QueryParameters empty = QueryParameters.empty();

        expect(empty.toString(), 'QueryParameters()');
      });
    });

    group('edge cases', () {
      test('handles special characters in keys', () {
        final QueryParameters query = QueryParameters({'key-name': 'value', 'key_name': 'value2'});

        expect(query.get('key-name'), 'value');
        expect(query.get('key_name'), 'value2');
      });

      test('handles empty string values', () {
        final QueryParameters query = QueryParameters({'token': ''});

        expect(query.get('token'), '');
        expect(query.has('token'), true);
      });

      test('handles single parameter', () {
        final QueryParameters query = QueryParameters({'only': 'one'});

        expect(query.length, 1);
        expect(query.get('only'), 'one');
      });

      test('round-trip conversion preserves data', () {
        final Map<String, dynamic> original = {
          'token': 'abc123',
          'room': 'chat',
          'count': '5',
        };
        final QueryParameters query = QueryParameters(original);
        final Map<String, dynamic> roundTrip = query.toDynamicMap();

        expect(roundTrip, equals(original));
      });

      test('query string round-trip preserves data', () {
        const String original = 'token=abc&room=chat';
        final QueryParameters query = QueryParameters.fromQueryString(original);
        final String roundTrip = query.toQueryString();

        // Note: order might differ, so parse and compare
        final QueryParameters reparsed = QueryParameters.fromQueryString(roundTrip);
        expect(reparsed, equals(query));
      });
    });
  });
}
