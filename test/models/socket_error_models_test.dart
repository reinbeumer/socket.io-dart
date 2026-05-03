import 'package:test/test.dart';
import 'package:socket_io/src/models/socket_error_models.dart';

void main() {
  group('SocketErrorType', () {
    test('enum has all expected values', () {
      expect(SocketErrorType.values, contains(SocketErrorType.connection));
      expect(SocketErrorType.values, contains(SocketErrorType.transport));
      expect(SocketErrorType.values, contains(SocketErrorType.timeout));
      expect(SocketErrorType.values, contains(SocketErrorType.authentication));
      expect(SocketErrorType.values, contains(SocketErrorType.invalidNamespace));
      expect(SocketErrorType.values, contains(SocketErrorType.parse));
      expect(SocketErrorType.values, contains(SocketErrorType.encoding));
      expect(SocketErrorType.values, contains(SocketErrorType.decoding));
      expect(SocketErrorType.values, contains(SocketErrorType.unknown));
    });
  });

  group('SocketErrorModel', () {
    test('creates with basic fields', () {
      const SocketErrorModel error = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Connection failed',
      );

      expect(error.type, equals(SocketErrorType.connection));
      expect(error.message, equals('Connection failed'));
      expect(error.originalError, isNull);
      expect(error.stackTrace, isNull);
    });

    test('connection factory creates connection error', () {
      final SocketErrorModel error = SocketErrorModel.connection('Failed to connect');

      expect(error.type, equals(SocketErrorType.connection));
      expect(error.message, equals('Failed to connect'));
    });

    test('transport factory creates transport error', () {
      final SocketErrorModel error = SocketErrorModel.transport(
        'Transport error',
        data: <String, Object?>{'code': 500},
      );

      expect(error.type, equals(SocketErrorType.transport));
      expect(error.message, equals('Transport error'));
      expect(error.data, equals(<String, Object?>{'code': 500}));
    });

    test('timeout factory creates timeout error with duration', () {
      final SocketErrorModel error = SocketErrorModel.timeout(
        'Request timed out',
        duration: const Duration(seconds: 30),
      );

      expect(error.type, equals(SocketErrorType.timeout));
      expect(error.message, equals('Request timed out'));
      expect(error.data?['duration'], equals(30000));
    });

    test('authentication factory creates auth error', () {
      final SocketErrorModel error = SocketErrorModel.authentication('Invalid token');

      expect(error.type, equals(SocketErrorType.authentication));
      expect(error.message, equals('Invalid token'));
    });

    test('invalidNamespace factory creates namespace error', () {
      final SocketErrorModel error = SocketErrorModel.invalidNamespace('/invalid');

      expect(error.type, equals(SocketErrorType.invalidNamespace));
      expect(error.message, contains('/invalid'));
      expect(error.data?['namespace'], equals('/invalid'));
    });

    test('parse factory creates parse error', () {
      final Exception original = Exception('Parse failed');
      final SocketErrorModel error = SocketErrorModel.parse(
        'Failed to parse',
        originalError: original,
      );

      expect(error.type, equals(SocketErrorType.parse));
      expect(error.message, equals('Failed to parse'));
      expect(error.originalError, equals(original));
    });

    test('encoding factory creates encoding error', () {
      final SocketErrorModel error = SocketErrorModel.encoding('Encoding failed');

      expect(error.type, equals(SocketErrorType.encoding));
      expect(error.message, equals('Encoding failed'));
    });

    test('decoding factory creates decoding error', () {
      final SocketErrorModel error = SocketErrorModel.decoding('Decoding failed');

      expect(error.type, equals(SocketErrorType.decoding));
      expect(error.message, equals('Decoding failed'));
    });

    test('unknown factory creates unknown error', () {
      final SocketErrorModel error = SocketErrorModel.unknown('Unknown error');

      expect(error.type, equals(SocketErrorType.unknown));
      expect(error.message, equals('Unknown error'));
    });

    test('fromObject creates from SocketErrorModel', () {
      const SocketErrorModel original = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Test',
      );

      final SocketErrorModel result = SocketErrorModel.fromObject(original);
      expect(result, same(original));
    });

    test('fromObject creates from Exception', () {
      final Exception original = Exception('Test exception');
      final SocketErrorModel error = SocketErrorModel.fromObject(original);

      expect(error.type, equals(SocketErrorType.unknown));
      expect(error.message, contains('Test exception'));
      expect(error.originalError, equals(original));
    });

    test('fromObject creates from generic object', () {
      const String original = 'Error string';
      final SocketErrorModel error = SocketErrorModel.fromObject(original);

      expect(error.type, equals(SocketErrorType.unknown));
      expect(error.message, contains('Error string'));
      expect(error.originalError, equals(original));
    });

    test('toMap converts to map', () {
      const SocketErrorModel error = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Connection failed',
        data: <String, Object?>{'code': 500},
      );

      final Map<String, Object?> map = error.toMap();
      expect(map['type'], equals('connection'));
      expect(map['message'], equals('Connection failed'));
      expect(map['data'], equals(<String, Object?>{'code': 500}));
    });

    test('toJson returns same as toMap', () {
      const SocketErrorModel error = SocketErrorModel(
        type: SocketErrorType.timeout,
        message: 'Timeout',
      );

      expect(error.toJson(), equals(error.toMap()));
    });

    test('equality works correctly', () {
      const SocketErrorModel error1 = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Same error',
      );

      const SocketErrorModel error2 = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Same error',
      );

      const SocketErrorModel error3 = SocketErrorModel(
        type: SocketErrorType.transport,
        message: 'Different error',
      );

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });

    test('hashCode works correctly', () {
      const SocketErrorModel error1 = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Test',
      );

      const SocketErrorModel error2 = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Test',
      );

      expect(error1.hashCode, equals(error2.hashCode));
    });

    test('toString provides useful representation', () {
      const SocketErrorModel error = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Test error',
      );

      final String str = error.toString();
      expect(str, contains('SocketErrorModel'));
      expect(str, contains('connection'));
      expect(str, contains('Test error'));
    });

    test('implements Exception', () {
      const SocketErrorModel error = SocketErrorModel(
        type: SocketErrorType.unknown,
        message: 'Test',
      );

      expect(error, isA<Exception>());
    });
  });

  group('ErrorConversion extension', () {
    test('toSocketError converts string', () {
      const String errorString = 'Error message';
      final SocketErrorModel error = errorString.toSocketError();

      expect(error.type, equals(SocketErrorType.unknown));
      expect(error.message, contains('Error message'));
    });

    test('toSocketError converts exception', () {
      final Exception exception = Exception('Test exception');
      final SocketErrorModel error = exception.toSocketError();

      expect(error.type, equals(SocketErrorType.unknown));
      expect(error.originalError, equals(exception));
    });

    test('toSocketError preserves SocketErrorModel', () {
      const SocketErrorModel original = SocketErrorModel(
        type: SocketErrorType.connection,
        message: 'Test',
      );

      final SocketErrorModel result = original.toSocketError();
      expect(result, same(original));
    });

    test('toSocketError accepts stacktrace', () {
      final StackTrace stackTrace = StackTrace.current;
      const String errorString = 'Error';
      final SocketErrorModel error = errorString.toSocketError(stackTrace);

      expect(error.stackTrace, equals(stackTrace));
    });
  });
}
