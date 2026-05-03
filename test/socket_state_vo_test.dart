import 'package:test/test.dart';
import 'package:socket_io/src/value_objects/socket_state_vo.dart';

void main() {
  group('SocketState', () {
    group('enum values', () {
      test('should have correct string values', () {
        expect(SocketState.connecting.value, equals('connecting'));
        expect(SocketState.connected.value, equals('connected'));
        expect(SocketState.disconnecting.value, equals('disconnecting'));
        expect(SocketState.disconnected.value, equals('disconnected'));
      });

      test('should have correct toString() output', () {
        expect(SocketState.connecting.toString(), equals('connecting'));
        expect(SocketState.connected.toString(), equals('connected'));
        expect(SocketState.disconnecting.toString(), equals('disconnecting'));
        expect(SocketState.disconnected.toString(), equals('disconnected'));
      });
    });

    group('fromString()', () {
      test('should parse valid state strings', () {
        expect(SocketState.fromString('connecting'), equals(SocketState.connecting));
        expect(SocketState.fromString('connected'), equals(SocketState.connected));
        expect(SocketState.fromString('disconnecting'), equals(SocketState.disconnecting));
        expect(SocketState.fromString('disconnected'), equals(SocketState.disconnected));
      });

      test('should return null for invalid strings', () {
        expect(SocketState.fromString('invalid'), isNull);
        expect(SocketState.fromString(''), isNull);
        expect(SocketState.fromString('CONNECTED'), isNull);
        expect(SocketState.fromString(' connected'), isNull);
      });
    });

    group('fromStringOrDefault()', () {
      test('should parse valid state strings', () {
        expect(
          SocketState.fromStringOrDefault('connected', SocketState.disconnected),
          equals(SocketState.connected),
        );
        expect(
          SocketState.fromStringOrDefault('connecting', SocketState.disconnected),
          equals(SocketState.connecting),
        );
      });

      test('should return default for invalid strings', () {
        expect(
          SocketState.fromStringOrDefault('invalid', SocketState.disconnected),
          equals(SocketState.disconnected),
        );
        expect(
          SocketState.fromStringOrDefault('', SocketState.connected),
          equals(SocketState.connected),
        );
      });
    });

    group('state check helpers', () {
      test('isConnected should return true only for connected state', () {
        expect(SocketState.connected.isConnected, isTrue);
        expect(SocketState.connecting.isConnected, isFalse);
        expect(SocketState.disconnecting.isConnected, isFalse);
        expect(SocketState.disconnected.isConnected, isFalse);
      });

      test('isDisconnected should return true only for disconnected state', () {
        expect(SocketState.disconnected.isDisconnected, isTrue);
        expect(SocketState.connecting.isDisconnected, isFalse);
        expect(SocketState.connected.isDisconnected, isFalse);
        expect(SocketState.disconnecting.isDisconnected, isFalse);
      });

      test('isTransitioning should return true for connecting/disconnecting', () {
        expect(SocketState.connecting.isTransitioning, isTrue);
        expect(SocketState.disconnecting.isTransitioning, isTrue);
        expect(SocketState.connected.isTransitioning, isFalse);
        expect(SocketState.disconnected.isTransitioning, isFalse);
      });

      test('canCommunicate should return true only when connected', () {
        expect(SocketState.connected.canCommunicate, isTrue);
        expect(SocketState.connecting.canCommunicate, isFalse);
        expect(SocketState.disconnecting.canCommunicate, isFalse);
        expect(SocketState.disconnected.canCommunicate, isFalse);
      });
    });

    group('exhaustive pattern matching', () {
      test('should handle all states in switch', () {
        String getStateMessage(final SocketState state) {
          switch (state) {
            case SocketState.connecting:
              return 'Establishing connection...';
            case SocketState.connected:
              return 'Connected and ready';
            case SocketState.disconnecting:
              return 'Closing connection...';
            case SocketState.disconnected:
              return 'Not connected';
          }
        }

        expect(getStateMessage(SocketState.connecting), equals('Establishing connection...'));
        expect(getStateMessage(SocketState.connected), equals('Connected and ready'));
        expect(getStateMessage(SocketState.disconnecting), equals('Closing connection...'));
        expect(getStateMessage(SocketState.disconnected), equals('Not connected'));
      });
    });

    group('state transitions', () {
      test('should represent typical connection lifecycle', () {
        final List<SocketState> lifecycle = <SocketState>[
          SocketState.disconnected,
          SocketState.connecting,
          SocketState.connected,
          SocketState.disconnecting,
          SocketState.disconnected,
        ];

        expect(lifecycle[0].isDisconnected, isTrue);
        expect(lifecycle[1].isTransitioning, isTrue);
        expect(lifecycle[2].canCommunicate, isTrue);
        expect(lifecycle[3].isTransitioning, isTrue);
        expect(lifecycle[4].isDisconnected, isTrue);
      });
    });
  });
}
