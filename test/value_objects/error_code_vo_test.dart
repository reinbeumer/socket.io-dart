import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/error_code_vo.dart';

void main() {
  group('ErrorCode', () {
    group('factory constructor', () {
      test('creates numeric code from numeric string', () {
        final ErrorCode code = ErrorCode('1001');
        expect(code.value, equals('1001'));
        expect(code.isNumeric, isTrue);
        expect(code.isString, isFalse);
        expect(code.numericValue, equals(1001));
      });

      test('creates string code from alphabetic string', () {
        final ErrorCode code = ErrorCode('AUTH_ERROR');
        expect(code.value, equals('AUTH_ERROR'));
        expect(code.isNumeric, isFalse);
        expect(code.isString, isTrue);
        expect(code.numericValue, isNull);
      });

      test('normalizes string code to uppercase', () {
        final ErrorCode code = ErrorCode('auth_error');
        expect(code.value, equals('AUTH_ERROR'));
      });

      test('accepts string codes with hyphens', () {
        final ErrorCode code = ErrorCode('AUTH-ERROR');
        expect(code.value, equals('AUTH-ERROR'));
      });

      test('accepts string codes with numbers', () {
        final ErrorCode code = ErrorCode('ERROR_404');
        expect(code.value, equals('ERROR_404'));
      });

      test('throws for empty string', () {
        expect(() => ErrorCode(''), throwsArgumentError);
      });

      test('throws for whitespace-only string', () {
        expect(() => ErrorCode('   '), throwsArgumentError);
      });

      test('throws for invalid characters in string code', () {
        expect(() => ErrorCode('error.code'), throwsArgumentError);
        expect(() => ErrorCode('error code'), throwsArgumentError);
        expect(() => ErrorCode('error@code'), throwsArgumentError);
      });

      test('trims whitespace from input', () {
        final ErrorCode code = ErrorCode('  1001  ');
        expect(code.value, equals('1001'));
      });
    });

    group('numeric factory', () {
      test('creates numeric code', () {
        final ErrorCode code = ErrorCode.numeric(1001);
        expect(code.value, equals('1001'));
        expect(code.isNumeric, isTrue);
        expect(code.numericValue, equals(1001));
      });

      test('accepts zero', () {
        final ErrorCode code = ErrorCode.numeric(0);
        expect(code.value, equals('0'));
        expect(code.numericValue, equals(0));
      });

      test('throws for negative numbers', () {
        expect(() => ErrorCode.numeric(-1), throwsArgumentError);
      });
    });

    group('string factory', () {
      test('creates string code', () {
        final ErrorCode code = ErrorCode.string('AUTH_ERROR');
        expect(code.value, equals('AUTH_ERROR'));
        expect(code.isString, isTrue);
        expect(code.numericValue, isNull);
      });

      test('normalizes to uppercase', () {
        final ErrorCode code = ErrorCode.string('auth_error');
        expect(code.value, equals('AUTH_ERROR'));
      });

      test('accepts codes with hyphens', () {
        final ErrorCode code = ErrorCode.string('AUTH-ERROR');
        expect(code.value, equals('AUTH-ERROR'));
      });

      test('accepts codes with numbers', () {
        final ErrorCode code = ErrorCode.string('ERROR404');
        expect(code.value, equals('ERROR404'));
      });

      test('throws for empty string', () {
        expect(() => ErrorCode.string(''), throwsArgumentError);
      });

      test('throws for whitespace-only string', () {
        expect(() => ErrorCode.string('   '), throwsArgumentError);
      });

      test('throws for invalid characters', () {
        expect(() => ErrorCode.string('error.code'), throwsArgumentError);
        expect(() => ErrorCode.string('error code'), throwsArgumentError);
      });

      test('trims whitespace', () {
        final ErrorCode code = ErrorCode.string('  AUTH_ERROR  ');
        expect(code.value, equals('AUTH_ERROR'));
      });
    });

    group('unchecked constructor', () {
      test('creates code without validation', () {
        final ErrorCode code = ErrorCode.unchecked('any value');
        expect(code.value, equals('any value'));
        expect(code.isNumeric, isFalse);
      });
    });

    group('common numeric codes', () {
      test('connection codes are defined', () {
        expect(ErrorCode.connectionTimeout.value, equals('1001'));
        expect(ErrorCode.connectionRefused.value, equals('1002'));
        expect(ErrorCode.connectionLost.value, equals('1003'));
        expect(ErrorCode.connectionFailed.value, equals('1004'));
      });

      test('transport codes are defined', () {
        expect(ErrorCode.transportError.value, equals('2001'));
        expect(ErrorCode.transportClosed.value, equals('2002'));
        expect(ErrorCode.transportTimeout.value, equals('2003'));
        expect(ErrorCode.transportFailed.value, equals('2004'));
      });

      test('protocol codes are defined', () {
        expect(ErrorCode.protocolError.value, equals('3001'));
        expect(ErrorCode.invalidPacket.value, equals('3002'));
      });

      test('auth codes are defined', () {
        expect(ErrorCode.authenticationFailed.value, equals('4001'));
        expect(ErrorCode.authorizationFailed.value, equals('4002'));
        expect(ErrorCode.invalidCredentials.value, equals('4003'));
      });

      test('unknown code is defined', () {
        expect(ErrorCode.unknown.value, equals('9999'));
      });
    });

    group('common string codes', () {
      test('string codes are defined', () {
        expect(ErrorCode.authError.value, equals('AUTH_ERROR'));
        expect(ErrorCode.timeoutError.value, equals('TIMEOUT_ERROR'));
        expect(ErrorCode.networkError.value, equals('NETWORK_ERROR'));
        expect(ErrorCode.parseError.value, equals('PARSE_ERROR'));
        expect(ErrorCode.invalidData.value, equals('INVALID_DATA'));
      });
    });

    group('equality', () {
      test('equal codes are equal', () {
        final ErrorCode code1 = ErrorCode('1001');
        final ErrorCode code2 = ErrorCode.numeric(1001);
        expect(code1, equals(code2));
      });

      test('different codes are not equal', () {
        final ErrorCode code1 = ErrorCode('1001');
        final ErrorCode code2 = ErrorCode('1002');
        expect(code1, isNot(equals(code2)));
      });

      test('numeric and string codes with same value are not equal', () {
        final ErrorCode code1 = ErrorCode('AUTH_ERROR');
        final ErrorCode code2 = ErrorCode.string('AUTH_ERROR');
        expect(code1, equals(code2));
      });
    });

    group('hashCode', () {
      test('equal codes have same hashCode', () {
        final ErrorCode code1 = ErrorCode('1001');
        final ErrorCode code2 = ErrorCode.numeric(1001);
        expect(code1.hashCode, equals(code2.hashCode));
      });
    });

    group('toString', () {
      test('provides meaningful representation', () {
        final ErrorCode code = ErrorCode('1001');
        expect(code.toString(), contains('ErrorCode'));
        expect(code.toString(), contains('1001'));
      });
    });

    group('edge cases', () {
      test('handles large numeric codes', () {
        final ErrorCode code = ErrorCode.numeric(99999);
        expect(code.value, equals('99999'));
        expect(code.numericValue, equals(99999));
      });

      test('handles single character string codes', () {
        final ErrorCode code = ErrorCode.string('E');
        expect(code.value, equals('E'));
      });

      test('handles long string codes', () {
        final String longCode = 'VERY_LONG_ERROR_CODE_NAME_FOR_TESTING';
        final ErrorCode code = ErrorCode.string(longCode);
        expect(code.value, equals(longCode));
      });

      test('handles codes with only underscores', () {
        final ErrorCode code = ErrorCode.string('___');
        expect(code.value, equals('___'));
      });

      test('handles codes with only hyphens', () {
        final ErrorCode code = ErrorCode.string('---');
        expect(code.value, equals('---'));
      });
    });
  });
}
