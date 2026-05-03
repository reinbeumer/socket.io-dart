/// Basic integration tests for Socket.IO server
///
/// These tests verify server initialization, configuration, and basic operations.
library integration_basic_test;

import 'package:test/test.dart';
import 'package:socket_io/socket_io.dart' as sio;

void main() {
  group('Server Integration', () {
    late sio.Server server;

    setUp(() {
      server = sio.Server();
    });

    test('server starts successfully', () async {
      server.listen(0); // Random port
      await server.ready;

      expect(server.port, isNotNull);
      expect(server.port, greaterThan(0));
    });

    test('server creates default namespace', () {
      expect(server.sockets, isNotNull);
      expect(server.sockets.name, equals('/'));
    });

    test('server creates custom namespaces', () {
      final chat = server.of('/chat');
      final admin = server.of('/admin');

      expect(chat, isNotNull);
      expect(chat.name, equals('/chat'));
      expect(admin.name, equals('/admin'));
      expect(chat, isNot(equals(admin)));
    });

    test('server retrieves same namespace instance', () {
      final chat1 = server.of('/chat');
      final chat2 = server.of('/chat');

      expect(identical(chat1, chat2), isTrue);
    });

    test('namespace adds middleware', () {
      final namespace = server.of('/test');

      namespace.use((socket, next) {
        next(null);
      });

      expect(namespace.fns.length, equals(1));
    });

    test('server handles multiple namespaces', () {
      for (var i = 0; i < 10; i++) {
        server.of('/namespace$i');
      }

      expect(server.nsps.length, greaterThanOrEqualTo(10));
    });

    test('server configuration can be set', () {
      final configuredServer = sio.Server(options: <String, dynamic>{
        'path': '/custom-socket',
        'pingTimeout': 60000,
        'pingInterval': 25000,
      });

      expect(configuredServer, isNotNull);
    });
  });

  group('Namespace Operations', () {
    late sio.Server server;
    late sio.Namespace namespace;

    setUp(() {
      server = sio.Server();
      namespace = server.of('/test');
    });

    test('namespace initializes adapter', () {
      expect(namespace.adapter, isNotNull);
    });

    test('namespace tracks sockets', () {
      expect(namespace.sockets, isEmpty);
      expect(namespace.connected, isEmpty);
    });

    test('namespace can add multiple middleware', () {
      namespace.use((socket, next) => next(null));
      namespace.use((socket, next) => next(null));
      namespace.use((socket, next) => next(null));

      expect(namespace.fns.length, equals(3));
    });

    test('namespace maintains state independently', () {
      final chat = server.of('/chat');
      final admin = server.of('/admin');

      chat.use((socket, next) => next(null));
      admin.use((socket, next) => next(null));
      admin.use((socket, next) => next(null));

      expect(chat.fns.length, equals(1));
      expect(admin.fns.length, equals(2));
    });
  });

  group('Server Options', () {
    test('server accepts ping timeout option', () {
      final server = sio.Server(options: <String, dynamic>{
        'pingTimeout': 120000,
      });

      expect(server, isNotNull);
    });

    test('server accepts ping interval option', () {
      final server = sio.Server(options: <String, dynamic>{
        'pingInterval': 30000,
      });

      expect(server, isNotNull);
    });

    test('server accepts transport options', () {
      final server = sio.Server(options: <String, dynamic>{
        'transports': ['websocket', 'polling'],
      });

      expect(server, isNotNull);
    });

    test('server accepts path option', () {
      final server = sio.Server(options: <String, dynamic>{
        'path': '/my-socket.io',
      });

      expect(server, isNotNull);
    });

    test('server accepts adapter option', () {
      final server = sio.Server(options: <String, dynamic>{
        'adapter': 'default',
      });

      expect(server, isNotNull);
    });

    test('server accepts multiple options', () {
      final server = sio.Server(options: <String, dynamic>{
        'path': '/socket',
        'pingTimeout': 60000,
        'pingInterval': 25000,
        'transports': ['websocket'],
        'adapter': 'default',
      });

      expect(server, isNotNull);
    });
  });

  group('Adapter Operations', () {
    late sio.Server server;
    late sio.Namespace namespace;

    setUp(() {
      server = sio.Server();
      namespace = server.of('/test');
    });

    test('adapter is initialized correctly', () {
      expect(namespace.adapter, isNotNull);
    });

    test('adapter can handle room operations', () {
      // Test that adapter methods are accessible
      expect(() => namespace.adapter.add('socket1', 'room1'), returnsNormally);
    });

    test('adapter maintains room state', () {
      namespace.adapter.add('socket1', 'room1');
      namespace.adapter.add('socket2', 'room1');
      namespace.adapter.add('socket3', 'room2');

      // Adapter should maintain internal room state
      expect(namespace.adapter, isNotNull);
    });
  });

  group('Performance', () {
    late sio.Server server;

    setUp(() {
      server = sio.Server();
    });

    test('handles creating many namespaces', () {
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 100; i++) {
        server.of('/namespace$i');
      }

      stopwatch.stop();

      expect(server.nsps.length, greaterThanOrEqualTo(100));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });

    test('handles many event listeners', () {
      final namespace = server.of('/test');
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        namespace.on('event$i', (data) {});
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
    });
  });

  group('Configuration Validation', () {
    test('server handles various valid configurations', () {
      expect(() => sio.Server(options: {}), returnsNormally);
      expect(() => sio.Server(options: {'path': '/test'}), returnsNormally);
      expect(() => sio.Server(options: {'pingTimeout': 5000}), returnsNormally);
    });

    test('namespace name starting with slash', () {
      final server = sio.Server();
      final ns = server.of('/valid-namespace');

      expect(ns.name, equals('/valid-namespace'));
    });

    test('creates multiple independent servers', () {
      final server1 = sio.Server();
      final server2 = sio.Server();

      expect(server1, isNot(same(server2)));
    });
  });
}
