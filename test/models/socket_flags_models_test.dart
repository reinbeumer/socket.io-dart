import 'package:test/test.dart';
import 'package:socket_io/src/models/socket_flags_models.dart';

void main() {
  group('SocketFlags', () {
    group('Constructors', () {
      test('default constructor creates with specified values', () {
        final SocketFlags flags = SocketFlags(
          json: true,
          volatile: true,
          broadcast: false,
          compress: false,
          preEncoded: false,
        );

        expect(flags.json, isTrue);
        expect(flags.volatile, isTrue);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('none() constructor creates all false flags', () {
        const SocketFlags flags = SocketFlags.none();

        expect(flags.json, isFalse);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('json() constructor creates json flag', () {
        const SocketFlags flags = SocketFlags.json();

        expect(flags.json, isTrue);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('volatile() constructor creates volatile flag', () {
        const SocketFlags flags = SocketFlags.volatile();

        expect(flags.json, isFalse);
        expect(flags.volatile, isTrue);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('broadcast() constructor creates broadcast flag', () {
        const SocketFlags flags = SocketFlags.broadcast();

        expect(flags.json, isFalse);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isTrue);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('compress() constructor creates compress flag', () {
        const SocketFlags flags = SocketFlags.compress();

        expect(flags.json, isFalse);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isTrue);
        expect(flags.preEncoded, isFalse);
      });

      test('preEncoded() constructor creates preEncoded flag', () {
        const SocketFlags flags = SocketFlags.preEncoded();

        expect(flags.json, isFalse);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isTrue);
      });
    });

    group('fromMap factory', () {
      test('creates from map with all flags', () {
        final SocketFlags flags = SocketFlags.fromMap(<String, bool>{
          'json': true,
          'volatile': true,
          'broadcast': true,
          'compress': true,
          'preEncoded': true,
        });

        expect(flags.json, isTrue);
        expect(flags.volatile, isTrue);
        expect(flags.broadcast, isTrue);
        expect(flags.compress, isTrue);
        expect(flags.preEncoded, isTrue);
      });

      test('creates from map with some flags', () {
        final SocketFlags flags = SocketFlags.fromMap(<String, bool>{
          'json': true,
          'compress': true,
        });

        expect(flags.json, isTrue);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isTrue);
        expect(flags.preEncoded, isFalse);
      });

      test('creates from empty map', () {
        final SocketFlags flags = SocketFlags.fromMap(<String, bool>{});

        expect(flags.json, isFalse);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });

      test('handles missing keys gracefully', () {
        final SocketFlags flags = SocketFlags.fromMap(<String, bool>{
          'json': true,
        });

        expect(flags.json, isTrue);
        expect(flags.volatile, isFalse);
        expect(flags.broadcast, isFalse);
        expect(flags.compress, isFalse);
        expect(flags.preEncoded, isFalse);
      });
    });

    group('toMap', () {
      test('converts to map with all flags', () {
        const SocketFlags flags = SocketFlags(
          json: true,
          volatile: true,
          broadcast: true,
          compress: true,
          preEncoded: true,
        );

        final Map<String, bool> map = flags.toMap();

        expect(map['json'], isTrue);
        expect(map['volatile'], isTrue);
        expect(map['broadcast'], isTrue);
        expect(map['compress'], isTrue);
        expect(map['preEncoded'], isTrue);
      });

      test('converts to map with only set flags', () {
        const SocketFlags flags = SocketFlags(
          json: true,
          compress: true,
        );

        final Map<String, bool> map = flags.toMap();

        expect(map['json'], isTrue);
        expect(map.containsKey('volatile'), isFalse);
        expect(map.containsKey('broadcast'), isFalse);
        expect(map['compress'], isTrue);
        expect(map.containsKey('preEncoded'), isFalse);
      });

      test('converts to empty map when no flags set', () {
        const SocketFlags flags = SocketFlags.none();

        final Map<String, bool> map = flags.toMap();

        expect(map.isEmpty, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified flags', () {
        const SocketFlags original = SocketFlags(
          json: true,
          volatile: false,
        );

        final SocketFlags modified = original.copyWith(
          volatile: true,
          compress: true,
        );

        expect(modified.json, isTrue);
        expect(modified.volatile, isTrue);
        expect(modified.broadcast, isFalse);
        expect(modified.compress, isTrue);
        expect(modified.preEncoded, isFalse);
      });

      test('creates copy with no changes when no parameters provided', () {
        const SocketFlags original = SocketFlags(
          json: true,
          volatile: true,
        );

        final SocketFlags copy = original.copyWith();

        expect(copy.json, equals(original.json));
        expect(copy.volatile, equals(original.volatile));
        expect(copy.broadcast, equals(original.broadcast));
        expect(copy.compress, equals(original.compress));
        expect(copy.preEncoded, equals(original.preEncoded));
      });

      test('can turn off flags', () {
        const SocketFlags original = SocketFlags(
          json: true,
          volatile: true,
          broadcast: true,
        );

        final SocketFlags modified = original.copyWith(
          volatile: false,
          broadcast: false,
        );

        expect(modified.json, isTrue);
        expect(modified.volatile, isFalse);
        expect(modified.broadcast, isFalse);
      });
    });

    group('hasAnyFlag', () {
      test('returns true when any flag is set', () {
        const SocketFlags flags1 = SocketFlags.json();
        const SocketFlags flags2 = SocketFlags.volatile();
        const SocketFlags flags3 = SocketFlags(json: true, compress: true);

        expect(flags1.hasAnyFlag, isTrue);
        expect(flags2.hasAnyFlag, isTrue);
        expect(flags3.hasAnyFlag, isTrue);
      });

      test('returns false when no flags are set', () {
        const SocketFlags flags = SocketFlags.none();

        expect(flags.hasAnyFlag, isFalse);
      });
    });

    group('hasNoFlags', () {
      test('returns true when no flags are set', () {
        const SocketFlags flags = SocketFlags.none();

        expect(flags.hasNoFlags, isTrue);
      });

      test('returns false when any flag is set', () {
        const SocketFlags flags1 = SocketFlags.json();
        const SocketFlags flags2 = SocketFlags(json: true, compress: true);

        expect(flags1.hasNoFlags, isFalse);
        expect(flags2.hasNoFlags, isFalse);
      });
    });

    group('equality', () {
      test('equal flags are equal', () {
        const SocketFlags flags1 = SocketFlags(json: true, volatile: true);
        const SocketFlags flags2 = SocketFlags(json: true, volatile: true);

        expect(flags1, equals(flags2));
      });

      test('different flags are not equal', () {
        const SocketFlags flags1 = SocketFlags(json: true);
        const SocketFlags flags2 = SocketFlags(volatile: true);

        expect(flags1, isNot(equals(flags2)));
      });

      test('none flags are equal', () {
        const SocketFlags flags1 = SocketFlags.none();
        const SocketFlags flags2 = SocketFlags();

        expect(flags1, equals(flags2));
      });
    });

    group('hashCode', () {
      test('equal flags have equal hashCodes', () {
        const SocketFlags flags1 = SocketFlags(json: true, volatile: true);
        const SocketFlags flags2 = SocketFlags(json: true, volatile: true);

        expect(flags1.hashCode, equals(flags2.hashCode));
      });

      test('different flags have different hashCodes', () {
        const SocketFlags flags1 = SocketFlags(json: true);
        const SocketFlags flags2 = SocketFlags(volatile: true);

        expect(flags1.hashCode, isNot(equals(flags2.hashCode)));
      });
    });

    group('toString', () {
      test('provides useful representation with flags', () {
        const SocketFlags flags = SocketFlags(json: true, compress: true);

        final String str = flags.toString();

        expect(str, contains('SocketFlags'));
        expect(str, contains('json'));
        expect(str, contains('compress'));
      });

      test('provides useful representation with no flags', () {
        const SocketFlags flags = SocketFlags.none();

        final String str = flags.toString();

        expect(str, contains('SocketFlags'));
        expect(str, contains('none'));
      });

      test('shows all flags when all are set', () {
        const SocketFlags flags = SocketFlags(
          json: true,
          volatile: true,
          broadcast: true,
          compress: true,
          preEncoded: true,
        );

        final String str = flags.toString();

        expect(str, contains('json'));
        expect(str, contains('volatile'));
        expect(str, contains('broadcast'));
        expect(str, contains('compress'));
        expect(str, contains('preEncoded'));
      });
    });

    group('MapToSocketFlags extension', () {
      test('converts map to SocketFlags', () {
        final Map<String, bool> map = <String, bool>{
          'json': true,
          'volatile': true,
        };

        final SocketFlags flags = map.toSocketFlags();

        expect(flags.json, isTrue);
        expect(flags.volatile, isTrue);
        expect(flags.broadcast, isFalse);
      });
    });

    group('NullableMapToSocketFlags extension', () {
      test('toSocketFlagsOrNone converts null to none', () {
        const Map<String, bool>? map = null;

        final SocketFlags flags = map.toSocketFlagsOrNone();

        expect(flags.hasNoFlags, isTrue);
      });

      test('toSocketFlagsOrNone converts map to SocketFlags', () {
        final Map<String, bool>? map = <String, bool>{
          'json': true,
        };

        final SocketFlags flags = map.toSocketFlagsOrNone();

        expect(flags.json, isTrue);
        expect(flags.volatile, isFalse);
      });

      test('toSocketFlagsOrNull converts null to null', () {
        const Map<String, bool>? map = null;

        final SocketFlags? flags = map.toSocketFlagsOrNull();

        expect(flags, isNull);
      });

      test('toSocketFlagsOrNull converts map to SocketFlags', () {
        final Map<String, bool>? map = <String, bool>{
          'compress': true,
        };

        final SocketFlags? flags = map.toSocketFlagsOrNull();

        expect(flags, isNotNull);
        expect(flags!.compress, isTrue);
        expect(flags.json, isFalse);
      });
    });
  });
}
