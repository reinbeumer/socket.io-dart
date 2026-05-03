import 'package:test/test.dart';
import 'package:socket_io/src/models/middleware_models.dart';
import 'package:socket_io/src/models/socket_error_models.dart';
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

void main() {
  group('MiddlewareContext', () {
    test('creates context with required fields', () {
      final MiddlewareContext context = MiddlewareContext(
        socket: 'test-socket',
        namespace: NamespaceName('/'),
      );
      expect(context.socket, equals('test-socket'));
      expect(context.namespace.value, equals('/'));
      expect(context.isRejected, isFalse);
    });

    test('includes auth data', () {
      final MiddlewareContext context = MiddlewareContext(
        socket: 'test-socket',
        namespace: NamespaceName('/'),
        auth: <String, dynamic>{'token': 'abc123'},
      );
      expect(context.auth, isNotNull);
      expect(context.auth!['token'], equals('abc123'));
    });

    test('rejects with error', () {
      final MiddlewareContext context = MiddlewareContext(
        socket: 'test-socket',
        namespace: NamespaceName('/'),
      );
      final SocketErrorModel error = SocketErrorModel.unauthorized('Bad auth');
      context.reject(error);

      expect(context.isRejected, isTrue);
      expect(context.error, equals(error));
    });

    test('rejects with message', () {
      final MiddlewareContext context = MiddlewareContext(
        socket: 'test-socket',
        namespace: NamespaceName('/'),
      );
      context.rejectWithMessage('Access denied');

      expect(context.isRejected, isTrue);
      expect(context.error, isNotNull);
    });

    test('sets and gets custom data', () {
      final MiddlewareContext context = MiddlewareContext(
        socket: 'test-socket',
        namespace: NamespaceName('/'),
      );
      context.setData('userId', 123);

      expect(context.getData('userId'), equals(123));
      expect(context.hasData('userId'), isTrue);
      expect(context.hasData('missing'), isFalse);
    });
  });

  group('MiddlewareResult', () {
    test('success result', () {
      const MiddlewareResult result = MiddlewareResult.success();
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.shouldContinue, isTrue);
    });

    test('failure result with error', () {
      final SocketErrorModel error = SocketErrorModel.unauthorized('Failed');
      final MiddlewareResult result = MiddlewareResult.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.shouldContinue, isFalse);
      expect(result.error, equals(error));
    });

    test('failure result with message', () {
      final MiddlewareResult result = MiddlewareResult.failureWithMessage('Error');
      expect(result.isFailure, isTrue);
      expect(result.error, isNotNull);
    });
  });

  group('MiddlewareChain', () {
    test('creates empty chain', () {
      final MiddlewareChain chain = MiddlewareChain();
      expect(chain.isEmpty, isTrue);
      expect(chain.length, equals(0));
    });

    test('creates with initial middlewares', () {
      final MiddlewareChain chain = MiddlewareChain.withMiddlewares(<MiddlewareFunction>[
        (final MiddlewareContext ctx) async => const MiddlewareResult.success(),
      ]);
      expect(chain.length, equals(1));
    });

    test('adds middleware', () {
      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());
      expect(chain.length, equals(1));
    });

    test('adds sync middleware', () {
      final MiddlewareChain chain = MiddlewareChain();
      chain.addSync((final MiddlewareContext ctx) => const MiddlewareResult.success());
      expect(chain.length, equals(1));
    });

    test('removes middleware', () {
      final MiddlewareFunction middleware = (final MiddlewareContext ctx) async => const MiddlewareResult.success();
      final MiddlewareChain chain = MiddlewareChain();
      chain.add(middleware);

      final bool removed = chain.remove(middleware);
      expect(removed, isTrue);
      expect(chain.isEmpty, isTrue);
    });

    test('clears all middlewares', () {
      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());

      chain.clear();
      expect(chain.isEmpty, isTrue);
    });

    test('executes successful chain', () async {
      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await chain.execute(context);
      expect(result.isSuccess, isTrue);
    });

    test('executes chain and stops on failure', () async {
      bool secondCalled = false;

      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async => MiddlewareResult.failureWithMessage('Failed'));
      chain.add((final MiddlewareContext ctx) async {
        secondCalled = true;
        return const MiddlewareResult.success();
      });

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await chain.execute(context);
      expect(result.isFailure, isTrue);
      expect(secondCalled, isFalse); // Second middleware should not run
    });

    test('detects context rejection', () async {
      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async {
        ctx.rejectWithMessage('Rejected');
        return const MiddlewareResult.success();
      });

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await chain.execute(context);
      expect(result.isFailure, isTrue);
    });

    test('toString provides useful representation', () {
      final MiddlewareChain chain = MiddlewareChain();
      chain.add((final MiddlewareContext ctx) async => const MiddlewareResult.success());

      expect(chain.toString(), contains('MiddlewareChain'));
      expect(chain.toString(), contains('1'));
    });
  });

  group('Middlewares common functions', () {
    test('logging middleware', () async {
      final List<String> logs = <String>[];
      final MiddlewareFunction middleware = Middlewares.logging(
        log: (final String msg) => logs.add(msg),
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/test'),
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isSuccess, isTrue);
      expect(logs, isNotEmpty);
      expect(logs.first, contains('/test'));
    });

    test('requireAuth middleware succeeds with valid auth', () async {
      final MiddlewareFunction middleware = Middlewares.requireAuth(
        validate: (final Map<String, dynamic> auth) async => true,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
        auth: <String, dynamic>{'user': 'test'},
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isSuccess, isTrue);
    });

    test('requireAuth middleware fails without auth', () async {
      final MiddlewareFunction middleware = Middlewares.requireAuth(
        validate: (final Map<String, dynamic> auth) async => true,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isFailure, isTrue);
    });

    test('requireAuth middleware fails with invalid auth', () async {
      final MiddlewareFunction middleware = Middlewares.requireAuth(
        validate: (final Map<String, dynamic> auth) async => false,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
        auth: <String, dynamic>{'user': 'test'},
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isFailure, isTrue);
    });

    test('requireToken middleware succeeds with valid token', () async {
      final MiddlewareFunction middleware = Middlewares.requireToken(
        tokenKey: 'token',
        validate: (final String token) => token == 'valid',
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
        auth: <String, dynamic>{'token': 'valid'},
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isSuccess, isTrue);
    });

    test('requireToken middleware fails with invalid token', () async {
      final MiddlewareFunction middleware = Middlewares.requireToken(
        tokenKey: 'token',
        validate: (final String token) => token == 'valid',
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
        auth: <String, dynamic>{'token': 'invalid'},
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isFailure, isTrue);
    });

    test('requireToken middleware fails without token', () async {
      final MiddlewareFunction middleware = Middlewares.requireToken(
        tokenKey: 'token',
        validate: (final String token) => true,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isFailure, isTrue);
    });

    test('rateLimit middleware succeeds when under limit', () async {
      final MiddlewareFunction middleware = Middlewares.rateLimit(
        checkLimit: (final dynamic socket) => true,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isSuccess, isTrue);
    });

    test('rateLimit middleware fails when over limit', () async {
      final MiddlewareFunction middleware = Middlewares.rateLimit(
        checkLimit: (final dynamic socket) => false,
      );

      final MiddlewareContext context = MiddlewareContext(
        socket: 'test',
        namespace: NamespaceName('/'),
      );

      final MiddlewareResult result = await middleware(context);
      expect(result.isFailure, isTrue);
    });
  });
}
