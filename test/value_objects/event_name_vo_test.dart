import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/event_name_vo.dart';

void main() {
  group('EventName', () {
    test('creates valid EventName from non-empty string', () {
      final EventName event = EventName('message');
      expect(event.value, equals('message'));
      expect(event.toString(), equals('message'));
    });

    test('accepts custom event names', () {
      final EventName event = EventName('custom-event');
      expect(event.value, equals('custom-event'));
    });

    test('throws ArgumentError for empty string', () {
      expect(() => EventName(''), throwsArgumentError);
    });

    test('throws ArgumentError for reserved names', () {
      expect(() => EventName('connect'), throwsArgumentError);
      expect(() => EventName('disconnect'), throwsArgumentError);
      expect(() => EventName('error'), throwsArgumentError);
      expect(() => EventName('connect_error'), throwsArgumentError);
    });

    test('equality works correctly', () {
      final EventName event1 = EventName('same-event');
      final EventName event2 = EventName('same-event');
      final EventName event3 = EventName('different-event');

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('hashCode works correctly', () {
      final EventName event1 = EventName('same-event');
      final EventName event2 = EventName('same-event');

      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('unchecked constructor allows reserved names', () {
      const EventName event = EventName.unchecked('connect');
      expect(event.value, equals('connect'));
    });

    test('reserved names set is defined', () {
      expect(EventName.reservedNames, isNotEmpty);
      expect(EventName.reservedNames, contains('connect'));
    });
  });
}
