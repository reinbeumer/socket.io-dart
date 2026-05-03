import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/url_path_vo.dart';

void main() {
  group('UrlPath', () {
    test('creates valid UrlPath starting with /', () {
      final UrlPath path = UrlPath('/api/v1');
      expect(path.value, equals('/api/v1'));
      expect(path.toString(), equals('/api/v1'));
    });

    test('accepts root path', () {
      final UrlPath path = UrlPath('/');
      expect(path.value, equals('/'));
    });

    test('accepts complex paths', () {
      final UrlPath path = UrlPath('/socket.io/v4/');
      expect(path.value, equals('/socket.io/v4/'));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => UrlPath(''), throwsArgumentError);
    });

    test('throws ArgumentError when not starting with /', () {
      expect(() => UrlPath('api/v1'), throwsArgumentError);
    });

    test('has default Socket.IO path constant', () {
      expect(UrlPath.defaultSocketIO.value, equals('/socket.io'));
    });

    test('has root path constant', () {
      expect(UrlPath.root.value, equals('/'));
    });

    test('equality works correctly', () {
      final UrlPath path1 = UrlPath('/same');
      final UrlPath path2 = UrlPath('/same');
      final UrlPath path3 = UrlPath('/different');

      expect(path1, equals(path2));
      expect(path1, isNot(equals(path3)));
    });

    test('hashCode works correctly', () {
      final UrlPath path1 = UrlPath('/same');
      final UrlPath path2 = UrlPath('/same');

      expect(path1.hashCode, equals(path2.hashCode));
    });

    test('unchecked constructor allows any value', () {
      const UrlPath path = UrlPath.unchecked('invalid');
      expect(path.value, equals('invalid'));
    });
  });
}
