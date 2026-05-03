import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/timeout_duration_vo.dart';

void main() {
  group('TimeoutDuration', () {
    test('creates valid TimeoutDuration from Duration', () {
      final TimeoutDuration timeout = TimeoutDuration(const Duration(seconds: 30));
      expect(timeout.value, equals(const Duration(seconds: 30)));
      expect(timeout.inSeconds, equals(30));
      expect(timeout.inMilliseconds, equals(30000));
    });

    test('creates from milliseconds', () {
      final TimeoutDuration timeout = TimeoutDuration.milliseconds(5000);
      expect(timeout.inMilliseconds, equals(5000));
      expect(timeout.inSeconds, equals(5));
    });

    test('creates from seconds', () {
      final TimeoutDuration timeout = TimeoutDuration.seconds(10);
      expect(timeout.inSeconds, equals(10));
    });

    test('creates from minutes', () {
      final TimeoutDuration timeout = TimeoutDuration.minutes(2);
      expect(timeout.inSeconds, equals(120));
    });

    test('throws ArgumentError for negative duration', () {
      expect(() => TimeoutDuration(const Duration(seconds: -1)), throwsArgumentError);
    });

    test('throws ArgumentError for duration exceeding 1 hour', () {
      expect(() => TimeoutDuration(const Duration(hours: 2)), throwsArgumentError);
    });

    test('allows duration up to 1 hour', () {
      final TimeoutDuration timeout = TimeoutDuration(const Duration(hours: 1));
      expect(timeout.inSeconds, equals(3600));
    });

    test('has default connection timeout', () {
      expect(TimeoutDuration.defaultConnection.inSeconds, equals(20));
    });

    test('has default ping timeout', () {
      expect(TimeoutDuration.defaultPing.inSeconds, equals(5));
    });

    test('equality works correctly', () {
      final TimeoutDuration timeout1 = TimeoutDuration.seconds(30);
      final TimeoutDuration timeout2 = TimeoutDuration.seconds(30);
      final TimeoutDuration timeout3 = TimeoutDuration.seconds(60);

      expect(timeout1, equals(timeout2));
      expect(timeout1, isNot(equals(timeout3)));
    });

    test('hashCode works correctly', () {
      final TimeoutDuration timeout1 = TimeoutDuration.seconds(30);
      final TimeoutDuration timeout2 = TimeoutDuration.seconds(30);

      expect(timeout1.hashCode, equals(timeout2.hashCode));
    });

    test('toString returns milliseconds', () {
      final TimeoutDuration timeout = TimeoutDuration.seconds(5);
      expect(timeout.toString(), equals('5000ms'));
    });

    test('unchecked constructor allows any value', () {
      const TimeoutDuration timeout = TimeoutDuration.unchecked(Duration(hours: 10));
      expect(timeout.value, equals(const Duration(hours: 10)));
    });
  });
}
