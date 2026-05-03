/// Tests for TypedEventEmitter
library;

import 'package:test/test.dart';
import 'package:socket_io/src/util/event_emitter.dart';

void main() {
  group('TypedEventEmitter<String>', () {
    late TypedEventEmitter<String> emitter;

    setUp(() {
      emitter = TypedEventEmitter<String>();
    });

    test('emits and receives string events', () {
      String? received;
      emitter.on('message', (final String data) {
        received = data;
      });
      emitter.emit('message', 'Hello World');
      expect(received, 'Hello World');
    });

    test('handles multiple listeners for same event', () {
      final List<String> received = <String>[];
      emitter.on('test', (final String data) => received.add('first: $data'));
      emitter.on('test', (final String data) => received.add('second: $data'));
      emitter.emit('test', 'data');
      expect(received, <String>['first: data', 'second: data']);
    });

    test('once listener called only once', () {
      int callCount = 0;
      emitter.once('oneTime', (final String data) => callCount++);
      emitter.emit('oneTime', 'first');
      emitter.emit('oneTime', 'second');
      expect(callCount, 1);
    });

    test('off removes specific handler', () {
      final List<String> received = <String>[];
      void handler(final String data) => received.add(data);
      emitter.on('test', handler);
      emitter.emit('test', 'before');
      emitter.off('test', handler);
      emitter.emit('test', 'after');
      expect(received, <String>['before']);
    });

    test('off without handler removes all handlers', () {
      int count = 0;
      emitter.on('test', (final String _) => count++);
      emitter.on('test', (final String _) => count++);
      emitter.off('test');
      emitter.emit('test', 'data');
      expect(count, 0);
    });

    test('clearListeners removes all event listeners', () {
      int count = 0;
      emitter.on('event1', (final String _) => count++);
      emitter.on('event2', (final String _) => count++);
      emitter.clearListeners();
      emitter.emit('event1', 'data');
      emitter.emit('event2', 'data');
      expect(count, 0);
    });

    test('hasListeners returns correct status', () {
      expect(emitter.hasListeners('test'), false);
      emitter.on('test', (final String _) {});
      expect(emitter.hasListeners('test'), true);
      emitter.off('test');
      expect(emitter.hasListeners('test'), false);
    });

    test('hasListeners includes once listeners', () {
      expect(emitter.hasListeners('test'), false);
      emitter.once('test', (final String _) {});
      expect(emitter.hasListeners('test'), true);
    });
  });

  group('TypedEventEmitter<int>', () {
    late TypedEventEmitter<int> emitter;

    setUp(() {
      emitter = TypedEventEmitter<int>();
    });

    test('emits and receives int events', () {
      int? received;
      emitter.on('count', (final int data) {
        received = data;
      });
      emitter.emit('count', 42);
      expect(received, 42);
    });

    test('handles multiple int emissions', () {
      final List<int> received = <int>[];
      emitter.on('numbers', (final int data) => received.add(data));
      emitter.emit('numbers', 1);
      emitter.emit('numbers', 2);
      emitter.emit('numbers', 3);
      expect(received, <int>[1, 2, 3]);
    });
  });

  group('TypedEventEmitter<Map<String, Object?>>', () {
    late TypedEventEmitter<Map<String, Object?>> emitter;

    setUp(() {
      emitter = TypedEventEmitter<Map<String, Object?>>();
    });

    test('emits and receives map events', () {
      Map<String, Object?>? received;
      emitter.on('data', (final Map<String, Object?> data) {
        received = data;
      });
      final Map<String, Object?> testData = <String, Object?>{'key': 'value', 'num': 123};
      emitter.emit('data', testData);
      expect(received, testData);
    });

    test('handles complex nested maps', () {
      Map<String, Object?>? received;
      emitter.on('nested', (final Map<String, Object?> data) {
        received = data;
      });
      final Map<String, Object?> nested = <String, Object?>{
        'user': <String, Object?>{'name': 'John', 'age': 30},
        'items': <Object?>[1, 2, 3],
      };
      emitter.emit('nested', nested);
      expect(received, nested);
    });
  });

  group('TypedEventEmitter edge cases', () {
    test('handler can be removed during emission', () {
      final TypedEventEmitter<String> emitter = TypedEventEmitter<String>();
      int count = 0;

      void handler(final String data) {
        count++;
        emitter.off('test', handler);
      }

      emitter.on('test', handler);
      emitter.on('test', (final String _) => count++);

      emitter.emit('test', 'data');
      expect(count, 2);

      emitter.emit('test', 'data');
      expect(count, 3); // Only second handler called
    });

    test('multiple once handlers all called once', () {
      final TypedEventEmitter<String> emitter = TypedEventEmitter<String>();
      int count1 = 0;
      int count2 = 0;

      emitter.once('test', (final String _) => count1++);
      emitter.once('test', (final String _) => count2++);

      emitter.emit('test', 'data');
      expect(count1, 1);
      expect(count2, 1);

      emitter.emit('test', 'data');
      expect(count1, 1);
      expect(count2, 1);
    });

    test('off on non-existent event does not throw', () {
      final TypedEventEmitter<String> emitter = TypedEventEmitter<String>();
      expect(() => emitter.off('nonExistent'), returnsNormally);
    });

    test('emit on event with no listeners does not throw', () {
      final TypedEventEmitter<String> emitter = TypedEventEmitter<String>();
      expect(() => emitter.emit('nonExistent', 'data'), returnsNormally);
    });
  });
}
