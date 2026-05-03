/// connect_buffer_models_test.dart
///
/// Tests for ConnectBuffer model
library connect_buffer_models_test;

import 'package:test/test.dart';
import 'package:socket_io/src/models/connect_buffer_models.dart';
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

void main() {
  group('ConnectBuffer', () {
    group('Constructors', () {
      test('default constructor creates empty buffer', () {
        final ConnectBuffer buffer = ConnectBuffer();

        expect(buffer.isEmpty, isTrue);
        expect(buffer.isNotEmpty, isFalse);
        expect(buffer.length, equals(0));
        expect(buffer.toList(), isEmpty);
      });

      test('fromList creates buffer with initial namespaces', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin', '/news']);

        expect(buffer.isEmpty, isFalse);
        expect(buffer.isNotEmpty, isTrue);
        expect(buffer.length, equals(3));
        expect(buffer.toList(), equals(<String>['/chat', '/admin', '/news']));
      });

      test('fromList creates independent copy', () {
        final List<String> original = <String>['/chat', '/admin'];
        final ConnectBuffer buffer = ConnectBuffer.fromList(original);

        original.add('/news');

        expect(buffer.length, equals(2));
        expect(buffer.toList(), equals(<String>['/chat', '/admin']));
      });
    });

    group('Adding namespaces', () {
      test('add adds namespace to buffer', () {
        final ConnectBuffer buffer = ConnectBuffer();

        buffer.add('/chat');

        expect(buffer.contains('/chat'), isTrue);
        expect(buffer.length, equals(1));
      });

      test('add does not add duplicate namespaces', () {
        final ConnectBuffer buffer = ConnectBuffer();

        buffer.add('/chat');
        buffer.add('/chat');
        buffer.add('/chat');

        expect(buffer.length, equals(1));
        expect(buffer.toList(), equals(<String>['/chat']));
      });

      test('addTyped adds namespace using NamespaceName', () {
        final ConnectBuffer buffer = ConnectBuffer();
        final NamespaceName namespace = NamespaceName('/chat');

        buffer.addTyped(namespace);

        expect(buffer.contains('/chat'), isTrue);
        expect(buffer.length, equals(1));
      });

      test('add multiple different namespaces', () {
        final ConnectBuffer buffer = ConnectBuffer();

        buffer.add('/chat');
        buffer.add('/admin');
        buffer.add('/news');

        expect(buffer.length, equals(3));
        expect(buffer.contains('/chat'), isTrue);
        expect(buffer.contains('/admin'), isTrue);
        expect(buffer.contains('/news'), isTrue);
      });
    });

    group('Removing namespaces', () {
      test('remove removes existing namespace', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        final bool removed = buffer.remove('/chat');

        expect(removed, isTrue);
        expect(buffer.contains('/chat'), isFalse);
        expect(buffer.length, equals(1));
      });

      test('remove returns false for non-existent namespace', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat']);

        final bool removed = buffer.remove('/admin');

        expect(removed, isFalse);
        expect(buffer.length, equals(1));
      });

      test('removeTyped removes namespace using NamespaceName', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);
        final NamespaceName namespace = NamespaceName('/chat');

        final bool removed = buffer.removeTyped(namespace);

        expect(removed, isTrue);
        expect(buffer.contains('/chat'), isFalse);
      });
    });

    group('Clearing buffer', () {
      test('clear removes all namespaces', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin', '/news']);

        buffer.clear();

        expect(buffer.isEmpty, isTrue);
        expect(buffer.length, equals(0));
        expect(buffer.toList(), isEmpty);
      });

      test('clear on empty buffer is safe', () {
        final ConnectBuffer buffer = ConnectBuffer();

        buffer.clear();

        expect(buffer.isEmpty, isTrue);
      });
    });

    group('Querying buffer', () {
      test('contains returns true for existing namespace', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        expect(buffer.contains('/chat'), isTrue);
        expect(buffer.contains('/admin'), isTrue);
      });

      test('contains returns false for non-existent namespace', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat']);

        expect(buffer.contains('/admin'), isFalse);
        expect(buffer.contains('/news'), isFalse);
      });

      test('containsTyped checks using NamespaceName', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat']);
        final NamespaceName exists = NamespaceName('/chat');
        final NamespaceName notExists = NamespaceName('/admin');

        expect(buffer.containsTyped(exists), isTrue);
        expect(buffer.containsTyped(notExists), isFalse);
      });

      test('toList returns immutable copy', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        final List<String> list = buffer.toList();

        expect(() => list.add('/news'), throwsUnsupportedError);
      });
    });

    group('Processing buffer', () {
      test('processAll calls processor for each namespace', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin', '/news']);
        final List<String> processed = <String>[];

        buffer.processAll((final String namespace) {
          processed.add(namespace);
        });

        expect(processed, equals(<String>['/chat', '/admin', '/news']));
      });

      test('processAll clears buffer after processing', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        buffer.processAll((final String namespace) {
          // Do nothing
        });

        expect(buffer.isEmpty, isTrue);
        expect(buffer.length, equals(0));
      });

      test('processAll handles empty buffer', () {
        final ConnectBuffer buffer = ConnectBuffer();
        int callCount = 0;

        buffer.processAll((final String namespace) {
          callCount++;
        });

        expect(callCount, equals(0));
        expect(buffer.isEmpty, isTrue);
      });

      test('processAll processes snapshot of buffer', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);
        final List<String> processed = <String>[];

        buffer.processAll((final String namespace) {
          processed.add(namespace);
          // Try to modify buffer during processing
          if (namespace == '/chat') {
            buffer.add('/news'); // This should not affect current processing
          }
        });

        expect(processed, equals(<String>['/chat', '/admin']));
        expect(buffer.contains('/news'), isTrue);
        expect(buffer.length, equals(1)); // Only '/news' remains
      });
    });

    group('Equality and hashCode', () {
      test('equal buffers are equal', () {
        final ConnectBuffer buffer1 = ConnectBuffer.fromList(<String>['/chat', '/admin']);
        final ConnectBuffer buffer2 = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        expect(buffer1, equals(buffer2));
        expect(buffer1.hashCode, equals(buffer2.hashCode));
      });

      test('different buffers are not equal', () {
        final ConnectBuffer buffer1 = ConnectBuffer.fromList(<String>['/chat', '/admin']);
        final ConnectBuffer buffer2 = ConnectBuffer.fromList(<String>['/chat', '/news']);

        expect(buffer1, isNot(equals(buffer2)));
      });

      test('empty buffers are equal', () {
        final ConnectBuffer buffer1 = ConnectBuffer();
        final ConnectBuffer buffer2 = ConnectBuffer();

        expect(buffer1, equals(buffer2));
        expect(buffer1.hashCode, equals(buffer2.hashCode));
      });

      test('different order is not equal', () {
        final ConnectBuffer buffer1 = ConnectBuffer.fromList(<String>['/chat', '/admin']);
        final ConnectBuffer buffer2 = ConnectBuffer.fromList(<String>['/admin', '/chat']);

        expect(buffer1, isNot(equals(buffer2)));
      });
    });

    group('toString', () {
      test('toString shows pending count and namespaces', () {
        final ConnectBuffer buffer = ConnectBuffer.fromList(<String>['/chat', '/admin']);

        final String str = buffer.toString();

        expect(str, contains('2 pending'));
        expect(str, contains('/chat'));
        expect(str, contains('/admin'));
      });

      test('toString for empty buffer', () {
        final ConnectBuffer buffer = ConnectBuffer();

        final String str = buffer.toString();

        expect(str, contains('0 pending'));
      });
    });
  });
}
