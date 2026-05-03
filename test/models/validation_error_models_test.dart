import 'package:test/test.dart';
import 'package:socket_io/src/models/validation_error_models.dart' as validation;

void main() {
  group('ValidationError', () {
    group('validation.RequiredFieldError', () {
      test('creates with field name', () {
        const validation.RequiredFieldError error = validation.RequiredFieldError(field: 'username');
        expect(error.field, equals('username'));
        expect(error.message, equals('Required field is missing'));
        expect(error.code, equals('required_field'));
      });

      test('creates with custom message', () {
        const validation.RequiredFieldError error = validation.RequiredFieldError(
          field: 'email',
          message: 'Email is required',
        );
        expect(error.message, equals('Email is required'));
      });

      test('toString includes field and message', () {
        const validation.RequiredFieldError error = validation.RequiredFieldError(field: 'name');
        expect(
          error.toString(),
          equals('ValidationError(name): Required field is missing [code: required_field]'),
        );
      });
    });

    group('validation.FormatError', () {
      test('creates with format and value', () {
        const validation.FormatError error = validation.FormatError(
          field: 'email',
          expectedFormat: 'email@example.com',
          actualValue: 'not-an-email',
        );
        expect(error.field, equals('email'));
        expect(error.expectedFormat, equals('email@example.com'));
        expect(error.actualValue, equals('not-an-email'));
      });

      test('toString includes format details', () {
        const validation.FormatError error = validation.FormatError(
          field: 'url',
          expectedFormat: 'http://...',
          actualValue: 'invalid',
        );
        expect(
          error.toString(),
          contains('Expected http://...'),
        );
        expect(error.toString(), contains('got invalid'));
      });
    });

    group('validation.RangeValidationError', () {
      test('creates with min and max', () {
        const validation.RangeValidationError error = validation.RangeValidationError(
          field: 'age',
          min: 0,
          max: 120,
          actualValue: -5,
        );
        expect(error.min, equals(0));
        expect(error.max, equals(120));
        expect(error.actualValue, equals(-5));
      });

      test('creates with only min', () {
        const validation.RangeValidationError error = validation.RangeValidationError(
          field: 'port',
          min: 1,
          actualValue: 0,
        );
        expect(error.min, equals(1));
        expect(error.max, isNull);
      });

      test('toString with min and max', () {
        const validation.RangeValidationError error = validation.RangeValidationError(
          field: 'value',
          min: 1,
          max: 100,
          actualValue: 150,
        );
        expect(error.toString(), contains('between 1 and 100'));
        expect(error.toString(), contains('got 150'));
      });

      test('toString with only min', () {
        const validation.RangeValidationError error = validation.RangeValidationError(
          field: 'value',
          min: 10,
          actualValue: 5,
        );
        expect(error.toString(), contains('at least 10'));
      });

      test('toString with only max', () {
        const validation.RangeValidationError error = validation.RangeValidationError(
          field: 'value',
          max: 100,
          actualValue: 150,
        );
        expect(error.toString(), contains('at most 100'));
      });
    });

    group('validation.LengthError', () {
      test('creates with min and max length', () {
        const validation.LengthError error = validation.LengthError(
          field: 'password',
          minLength: 8,
          maxLength: 32,
          actualLength: 5,
        );
        expect(error.minLength, equals(8));
        expect(error.maxLength, equals(32));
        expect(error.actualLength, equals(5));
      });

      test('toString describes length constraint', () {
        const validation.LengthError error = validation.LengthError(
          field: 'name',
          minLength: 1,
          maxLength: 50,
          actualLength: 100,
        );
        expect(error.toString(), contains('between 1 and 50 characters'));
        expect(error.toString(), contains('got 100'));
      });
    });

    group('validation.InvalidValueError', () {
      test('creates with allowed values', () {
        const validation.InvalidValueError error = validation.InvalidValueError(
          field: 'status',
          allowedValues: <String>['active', 'inactive'],
          actualValue: 'unknown',
        );
        expect(error.allowedValues, equals(<String>['active', 'inactive']));
        expect(error.actualValue, equals('unknown'));
      });

      test('toString shows allowed values', () {
        const validation.InvalidValueError error = validation.InvalidValueError(
          field: 'type',
          allowedValues: <int>[1, 2, 3],
          actualValue: 5,
        );
        expect(error.toString(), contains('Expected one of'));
        expect(error.toString(), contains('[1, 2, 3]'));
        expect(error.toString(), contains('got 5'));
      });
    });

    group('validation.CustomValidationError', () {
      test('creates with message and details', () {
        const validation.CustomValidationError error = validation.CustomValidationError(
          field: 'data',
          message: 'Invalid data structure',
          details: <String, Object?>{'reason': 'missing key'},
        );
        expect(error.message, equals('Invalid data structure'));
        expect(error.details, isNotNull);
        expect(error.details!['reason'], equals('missing key'));
      });

      test('toString includes details', () {
        const validation.CustomValidationError error = validation.CustomValidationError(
          field: 'config',
          message: 'Invalid configuration',
          details: <String, String>{'key': 'timeout'},
        );
        expect(error.toString(), contains('Invalid configuration'));
        expect(error.toString(), contains('details:'));
      });
    });
  });

  group('validation.ValidationResult', () {
    group('validation.ValidationSuccess', () {
      test('creates with value', () {
        const validation.ValidationSuccess<String> result = validation.ValidationSuccess<String>('test');
        expect(result.value, equals('test'));
        expect(result.isValid, isTrue);
        expect(result.isInvalid, isFalse);
      });

      test('getOrElse returns value', () {
        const validation.ValidationSuccess<int> result = validation.ValidationSuccess<int>(42);
        expect(result.getOrElse(() => 0), equals(42));
      });

      test('getOrDefault returns value', () {
        const validation.ValidationSuccess<String> result = validation.ValidationSuccess<String>('hello');
        expect(result.getOrDefault('default'), equals('hello'));
      });

      test('map transforms value', () {
        const validation.ValidationSuccess<int> result = validation.ValidationSuccess<int>(10);
        final validation.ValidationResult<String> mapped = result.map((int n) => n.toString());
        expect(mapped.isValid, isTrue);
        expect(mapped.value, equals('10'));
      });

      test('flatMap chains operations', () {
        const validation.ValidationSuccess<int> result = validation.ValidationSuccess<int>(10);
        final validation.ValidationResult<String> flatMapped = result.flatMap(
          (int n) => validation.ValidationSuccess<String>(n.toString()),
        );
        expect(flatMapped.isValid, isTrue);
        expect(flatMapped.value, equals('10'));
      });

      test('equality works correctly', () {
        const validation.ValidationSuccess<int> result1 = validation.ValidationSuccess<int>(42);
        const validation.ValidationSuccess<int> result2 = validation.ValidationSuccess<int>(42);
        const validation.ValidationSuccess<int> result3 = validation.ValidationSuccess<int>(43);

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('hashCode is consistent', () {
        const validation.ValidationSuccess<String> result1 = validation.ValidationSuccess<String>('test');
        const validation.ValidationSuccess<String> result2 = validation.ValidationSuccess<String>('test');
        expect(result1.hashCode, equals(result2.hashCode));
      });
    });

    group('validation.ValidationFailure', () {
      test('creates with errors list', () {
        const validation.ValidationFailure<String> result =
            validation.ValidationFailure<String>(<validation.ValidationError>[
          validation.RequiredFieldError(field: 'name'),
        ]);
        expect(result.errors, hasLength(1));
        expect(result.isValid, isFalse);
        expect(result.isInvalid, isTrue);
      });

      test('creates with single error', () {
        final validation.ValidationFailure<int> result = validation.ValidationFailure<int>.single(
          const validation.RangeValidationError(field: 'age', min: 0, actualValue: -1),
        );
        expect(result.errors, hasLength(1));
      });

      test('getOrElse calls orElse function', () {
        final validation.ValidationFailure<int> result = validation.ValidationFailure<int>.single(
          const validation.RequiredFieldError(field: 'value'),
        );
        expect(result.getOrElse(() => 0), equals(0));
      });

      test('getOrDefault returns default', () {
        final validation.ValidationFailure<String> result = validation.ValidationFailure<String>.single(
          const validation.RequiredFieldError(field: 'name'),
        );
        expect(result.getOrDefault('default'), equals('default'));
      });

      test('value throws StateError', () {
        final validation.ValidationFailure<String> result = validation.ValidationFailure<String>.single(
          const validation.RequiredFieldError(field: 'test'),
        );
        expect(() => result.value, throwsStateError);
      });

      test('map preserves errors', () {
        final validation.ValidationFailure<int> result = validation.ValidationFailure<int>.single(
          const validation.RequiredFieldError(field: 'num'),
        );
        final validation.ValidationResult<String> mapped = result.map((int n) => n.toString());
        expect(mapped.isInvalid, isTrue);
        expect(mapped.errors, hasLength(1));
      });

      test('flatMap preserves errors', () {
        final validation.ValidationFailure<int> result = validation.ValidationFailure<int>.single(
          const validation.RequiredFieldError(field: 'num'),
        );
        final validation.ValidationResult<String> flatMapped = result.flatMap(
          (int n) => validation.ValidationSuccess<String>(n.toString()),
        );
        expect(flatMapped.isInvalid, isTrue);
      });

      test('toString includes error count', () {
        const validation.ValidationFailure<String> result =
            validation.ValidationFailure<String>(<validation.ValidationError>[
          validation.RequiredFieldError(field: 'name'),
          validation.RequiredFieldError(field: 'email'),
        ]);
        expect(result.toString(), contains('2 errors'));
      });
    });
  });

  group('validation.ValidationUtils', () {
    group('required', () {
      test('succeeds for non-null value', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.required<String>('test', 'field');
        expect(result.isValid, isTrue);
        expect(result.value, equals('test'));
      });

      test('fails for null value', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.required<String>(null, 'field');
        expect(result.isInvalid, isTrue);
        expect(result.errors.first, isA<validation.RequiredFieldError>());
      });
    });

    group('nonEmpty', () {
      test('succeeds for non-empty string', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.nonEmpty('hello', 'field');
        expect(result.isValid, isTrue);
      });

      test('fails for empty string', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.nonEmpty('', 'field');
        expect(result.isInvalid, isTrue);
      });
    });

    group('inRange', () {
      test('succeeds for value in range', () {
        final validation.ValidationResult<int> result =
            validation.ValidationUtils.inRange<int>(50, 'field', min: 0, max: 100);
        expect(result.isValid, isTrue);
      });

      test('fails for value below min', () {
        final validation.ValidationResult<int> result = validation.ValidationUtils.inRange<int>(-1, 'field', min: 0);
        expect(result.isInvalid, isTrue);
        expect(result.errors.first, isA<validation.RangeValidationError>());
      });

      test('fails for value above max', () {
        final validation.ValidationResult<int> result = validation.ValidationUtils.inRange<int>(101, 'field', max: 100);
        expect(result.isInvalid, isTrue);
      });
    });

    group('lengthInRange', () {
      test('succeeds for valid length', () {
        final validation.ValidationResult<String> result =
            validation.ValidationUtils.lengthInRange('hello', 'field', minLength: 1, maxLength: 10);
        expect(result.isValid, isTrue);
      });

      test('fails for too short', () {
        final validation.ValidationResult<String> result =
            validation.ValidationUtils.lengthInRange('hi', 'field', minLength: 5);
        expect(result.isInvalid, isTrue);
        expect(result.errors.first, isA<validation.LengthError>());
      });

      test('fails for too long', () {
        final validation.ValidationResult<String> result =
            validation.ValidationUtils.lengthInRange('verylongstring', 'field', maxLength: 5);
        expect(result.isInvalid, isTrue);
      });
    });

    group('matchesPattern', () {
      test('succeeds for matching pattern', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.matchesPattern(
          'test@example.com',
          'email',
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
        );
        expect(result.isValid, isTrue);
      });

      test('fails for non-matching pattern', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.matchesPattern(
          'not-an-email',
          'email',
          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
        );
        expect(result.isInvalid, isTrue);
        expect(result.errors.first, isA<validation.FormatError>());
      });
    });

    group('oneOf', () {
      test('succeeds for allowed value', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.oneOf<String>(
          'active',
          'status',
          <String>['active', 'inactive'],
        );
        expect(result.isValid, isTrue);
      });

      test('fails for disallowed value', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.oneOf<String>(
          'unknown',
          'status',
          <String>['active', 'inactive'],
        );
        expect(result.isInvalid, isTrue);
        expect(result.errors.first, isA<validation.InvalidValueError>());
      });
    });

    group('combine', () {
      test('succeeds when all validations pass', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.combine<String>(
          'test',
          <validation.ValidationResult<String>>[
            const validation.ValidationSuccess<String>('test'),
            const validation.ValidationSuccess<String>('test'),
          ],
        );
        expect(result.isValid, isTrue);
      });

      test('fails when any validation fails', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.combine<String>(
          'test',
          <validation.ValidationResult<String>>[
            const validation.ValidationSuccess<String>('test'),
            validation.ValidationFailure<String>.single(const validation.RequiredFieldError(field: 'test')),
          ],
        );
        expect(result.isInvalid, isTrue);
      });

      test('collects all errors', () {
        final validation.ValidationResult<String> result = validation.ValidationUtils.combine<String>(
          'test',
          <validation.ValidationResult<String>>[
            validation.ValidationFailure<String>.single(const validation.RequiredFieldError(field: 'field1')),
            validation.ValidationFailure<String>.single(const validation.RequiredFieldError(field: 'field2')),
          ],
        );
        expect(result.isInvalid, isTrue);
        expect(result.errors, hasLength(2));
      });
    });
  });
}
