import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

void main() {
  group('NamespaceName', () {
    test('creates valid NamespaceName starting with /', () {
      final NamespaceName ns = NamespaceName('/test');
      expect(ns.value, equals('/test'));
      expect(ns.toString(), equals('/test'));
    });

    test('accepts default namespace', () {
      final NamespaceName ns = NamespaceName('/');
      expect(ns.value, equals('/'));
    });

    test('accepts complex namespace paths', () {
      final NamespaceName ns = NamespaceName('/chat/room-1');
      expect(ns.value, equals('/chat/room-1'));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => NamespaceName(''), throwsArgumentError);
    });

    test('throws ArgumentError when not starting with /', () {
      expect(() => NamespaceName('test'), throwsArgumentError);
    });

    test('throws ArgumentError for invalid characters', () {
      expect(() => NamespaceName('/test space'), throwsArgumentError);
      expect(() => NamespaceName('/test?query'), throwsArgumentError);
    });

    test('equality works correctly', () {
      final NamespaceName ns1 = NamespaceName('/same');
      final NamespaceName ns2 = NamespaceName('/same');
      final NamespaceName ns3 = NamespaceName('/different');

      expect(ns1, equals(ns2));
      expect(ns1, isNot(equals(ns3)));
    });

    test('defaultNamespace constant is available', () {
      expect(NamespaceName.defaultNamespace.value, equals('/'));
    });

    test('unchecked constructor allows any value', () {
      const NamespaceName ns = NamespaceName.unchecked('invalid');
      expect(ns.value, equals('invalid'));
    });
  });
}
