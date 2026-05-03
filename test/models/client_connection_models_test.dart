/// client_connection_models_test.dart
///
/// Tests for client connection state models
library client_connection_models_test;

import 'package:test/test.dart';
import 'package:socket_io/src/models/client_connection_models.dart';
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

void main() {
  group('ClientConnectionState', () {
    test('isActive is true only for connected state', () {
      expect(ClientConnectionState.connecting.isActive, isFalse);
      expect(ClientConnectionState.connected.isActive, isTrue);
      expect(ClientConnectionState.disconnecting.isActive, isFalse);
      expect(ClientConnectionState.disconnected.isActive, isFalse);
      expect(ClientConnectionState.error.isActive, isFalse);
    });

    test('isTransitioning is true for connecting and disconnecting', () {
      expect(ClientConnectionState.connecting.isTransitioning, isTrue);
      expect(ClientConnectionState.connected.isTransitioning, isFalse);
      expect(ClientConnectionState.disconnecting.isTransitioning, isTrue);
      expect(ClientConnectionState.disconnected.isTransitioning, isFalse);
      expect(ClientConnectionState.error.isTransitioning, isFalse);
    });

    test('isInactive is true for disconnected and error states', () {
      expect(ClientConnectionState.connecting.isInactive, isFalse);
      expect(ClientConnectionState.connected.isInactive, isFalse);
      expect(ClientConnectionState.disconnecting.isInactive, isFalse);
      expect(ClientConnectionState.disconnected.isInactive, isTrue);
      expect(ClientConnectionState.error.isInactive, isTrue);
    });

    test('description returns human-readable text', () {
      expect(ClientConnectionState.connecting.description, contains('Establishing'));
      expect(ClientConnectionState.connected.description, contains('Connected'));
      expect(ClientConnectionState.disconnecting.description, contains('Disconnecting'));
      expect(ClientConnectionState.disconnected.description, contains('Disconnected'));
      expect(ClientConnectionState.error.description, contains('error'));
    });
  });

  group('NamespaceConnectionInfo', () {
    test('creates instance with required fields', () {
      final DateTime now = DateTime.now();
      final NamespaceName namespace = NamespaceName('/test');

      final NamespaceConnectionInfo info = NamespaceConnectionInfo(
        namespace: namespace,
        connectedAt: now,
      );

      expect(info.namespace, equals(namespace));
      expect(info.connectedAt, equals(now));
      expect(info.isDefault, isFalse);
      expect(info.socketCount, equals(1));
    });

    test('creates default namespace instance', () {
      final DateTime now = DateTime.now();

      final NamespaceConnectionInfo info = NamespaceConnectionInfo.defaultNamespace(
        connectedAt: now,
      );

      expect(info.namespace.value, equals('/'));
      expect(info.isDefault, isTrue);
      expect(info.connectedAt, equals(now));
    });

    test('calculates connection duration', () {
      final DateTime past = DateTime.now().subtract(const Duration(seconds: 5));

      final NamespaceConnectionInfo info = NamespaceConnectionInfo(
        namespace: NamespaceName('/test'),
        connectedAt: past,
      );

      expect(info.connectedDuration.inSeconds, greaterThanOrEqualTo(4));
    });

    test('copyWith creates new instance with updated values', () {
      final NamespaceConnectionInfo original = NamespaceConnectionInfo(
        namespace: NamespaceName('/test'),
        connectedAt: DateTime.now(),
        socketCount: 1,
      );

      final NamespaceConnectionInfo updated = original.copyWith(
        socketCount: 2,
      );

      expect(updated.socketCount, equals(2));
      expect(updated.namespace, equals(original.namespace));
      expect(updated.connectedAt, equals(original.connectedAt));
    });

    test('equality works correctly', () {
      final DateTime now = DateTime.now();
      final NamespaceName namespace = NamespaceName('/test');

      final NamespaceConnectionInfo info1 = NamespaceConnectionInfo(
        namespace: namespace,
        connectedAt: now,
      );

      final NamespaceConnectionInfo info2 = NamespaceConnectionInfo(
        namespace: namespace,
        connectedAt: now,
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });

    test('toString includes all important info', () {
      final NamespaceConnectionInfo info = NamespaceConnectionInfo(
        namespace: NamespaceName('/test'),
        connectedAt: DateTime.now(),
        socketCount: 3,
      );

      final String str = info.toString();

      expect(str, contains('/test'));
      expect(str, contains('socketCount: 3'));
    });
  });

  group('ClientConnectionState2', () {
    test('creates connecting state', () {
      final ClientConnectionState2 state = ClientConnectionState2.connecting();

      expect(state.state, equals(ClientConnectionState.connecting));
      expect(state.namespaces, isEmpty);
      expect(state.initialConnectionTime, isNotNull);
      expect(state.lastError, isNull);
    });

    test('creates connected state', () {
      final ClientConnectionState2 state = ClientConnectionState2.connected();

      expect(state.state, equals(ClientConnectionState.connected));
      expect(state.namespaces, isEmpty);
      expect(state.initialConnectionTime, isNotNull);
    });

    test('creates disconnected state with reason', () {
      final ClientConnectionState2 state = ClientConnectionState2.disconnected(reason: 'User logout');

      expect(state.state, equals(ClientConnectionState.disconnected));
      expect(state.lastError, equals('User logout'));
    });

    test('creates error state', () {
      final ClientConnectionState2 state = ClientConnectionState2.error('Connection timeout');

      expect(state.state, equals(ClientConnectionState.error));
      expect(state.lastError, equals('Connection timeout'));
    });

    test('hasNamespaces is false for empty state', () {
      final ClientConnectionState2 state = ClientConnectionState2.connected();

      expect(state.hasNamespaces, isFalse);
      expect(state.namespaceCount, equals(0));
    });

    test('hasDefaultNamespace detects default namespace', () {
      final NamespaceConnectionInfo info = NamespaceConnectionInfo.defaultNamespace(
        connectedAt: DateTime.now(),
      );

      final ClientConnectionState2 state = ClientConnectionState2.connected(
        namespaces: <String, NamespaceConnectionInfo>{'/': info},
      );

      expect(state.hasDefaultNamespace, isTrue);
    });

    test('addNamespace updates state', () {
      final ClientConnectionState2 initialState = ClientConnectionState2.connecting();

      final NamespaceConnectionInfo info = NamespaceConnectionInfo(
        namespace: NamespaceName('/test'),
        connectedAt: DateTime.now(),
      );

      final ClientConnectionState2 updatedState = initialState.addNamespace('/test', info);

      expect(updatedState.hasNamespaces, isTrue);
      expect(updatedState.namespaceCount, equals(1));
      expect(updatedState.namespaces.containsKey('/test'), isTrue);
      expect(updatedState.state, equals(ClientConnectionState.connected));
    });

    test('removeNamespace updates state', () {
      final NamespaceConnectionInfo info = NamespaceConnectionInfo(
        namespace: NamespaceName('/test'),
        connectedAt: DateTime.now(),
      );

      final ClientConnectionState2 initialState = ClientConnectionState2.connected(
        namespaces: <String, NamespaceConnectionInfo>{'/test': info},
      );

      final ClientConnectionState2 updatedState = initialState.removeNamespace('/test');

      expect(updatedState.hasNamespaces, isFalse);
      expect(updatedState.namespaceCount, equals(0));
    });

    test('isActive is true only when connected with namespaces', () {
      final ClientConnectionState2 connectingState = ClientConnectionState2.connecting();
      expect(connectingState.isActive, isFalse);

      final ClientConnectionState2 connectedEmpty = ClientConnectionState2.connected();
      expect(connectedEmpty.isActive, isFalse);

      final NamespaceConnectionInfo info = NamespaceConnectionInfo.defaultNamespace(
        connectedAt: DateTime.now(),
      );

      final ClientConnectionState2 connectedWithNs = ClientConnectionState2.connected(
        namespaces: <String, NamespaceConnectionInfo>{'/': info},
      );
      expect(connectedWithNs.isActive, isTrue);
    });

    test('totalConnectionDuration is null when no initial time', () {
      const ClientConnectionState2 state = ClientConnectionState2(
        state: ClientConnectionState.disconnected,
      );

      expect(state.totalConnectionDuration, isNull);
    });

    test('totalConnectionDuration calculates correctly', () {
      final ClientConnectionState2 state = ClientConnectionState2.connecting();

      // Small delay to ensure duration is measurable
      expect(state.totalConnectionDuration, isNotNull);
      expect(state.totalConnectionDuration!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('copyWith creates new instance with updated values', () {
      final ClientConnectionState2 original = ClientConnectionState2.connecting();

      final ClientConnectionState2 updated = original.copyWith(
        state: ClientConnectionState.connected,
        lastError: 'Test error',
      );

      expect(updated.state, equals(ClientConnectionState.connected));
      expect(updated.lastError, equals('Test error'));
      expect(updated.initialConnectionTime, equals(original.initialConnectionTime));
    });

    test('toString includes relevant information', () {
      final ClientConnectionState2 state = ClientConnectionState2.error('Test error');

      final String str = state.toString();

      expect(str, contains('error'));
      expect(str, contains('Test error'));
    });

    test('manages multiple namespaces', () {
      final NamespaceConnectionInfo info1 = NamespaceConnectionInfo.defaultNamespace(
        connectedAt: DateTime.now(),
      );

      final NamespaceConnectionInfo info2 = NamespaceConnectionInfo(
        namespace: NamespaceName('/chat'),
        connectedAt: DateTime.now(),
      );

      final NamespaceConnectionInfo info3 = NamespaceConnectionInfo(
        namespace: NamespaceName('/notifications'),
        connectedAt: DateTime.now(),
      );

      ClientConnectionState2 state = ClientConnectionState2.connected();
      state = state.addNamespace('/', info1);
      state = state.addNamespace('/chat', info2);
      state = state.addNamespace('/notifications', info3);

      expect(state.namespaceCount, equals(3));
      expect(state.hasDefaultNamespace, isTrue);
      expect(state.isActive, isTrue);

      state = state.removeNamespace('/chat');
      expect(state.namespaceCount, equals(2));
    });
  });
}
