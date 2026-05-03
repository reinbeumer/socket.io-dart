// namespace_config_models_test.dart
//
// Purpose: Tests for namespace configuration models

import 'package:test/test.dart';
import 'package:socket_io/src/models/namespace_config_models.dart';
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

void main() {
  group('NamespaceConfig', () {
    test('creates config with required fields', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config = NamespaceConfig(name: name);

      expect(config.name, equals(name));
      expect(config.adapterFactory, isNull);
      expect(config.middleware, isEmpty);
      expect(config.autoCreate, isTrue);
      expect(config.maxSockets, isNull);
    });

    test('creates config with all fields', () {
      final NamespaceName name = NamespaceName('/test');
      final List<dynamic Function(Object, void Function(Object?))> middleware =
          <dynamic Function(Object, void Function(Object?))>[
        (final Object socket, final void Function(Object?) next) => next(null),
      ];

      final NamespaceConfig config = NamespaceConfig(
        name: name,
        middleware: middleware,
        autoCreate: false,
        maxSockets: 100,
      );

      expect(config.name, equals(name));
      expect(config.middleware, hasLength(1));
      expect(config.autoCreate, isFalse);
      expect(config.maxSockets, equals(100));
    });

    test('creates config from string', () {
      final NamespaceConfig config = NamespaceConfig.fromString('/test');

      expect(config.name.value, equals('/test'));
      expect(config.autoCreate, isTrue);
    });

    test('creates config from string with options', () {
      final NamespaceConfig config = NamespaceConfig.fromString(
        '/test',
        autoCreate: false,
        maxSockets: 50,
      );

      expect(config.name.value, equals('/test'));
      expect(config.autoCreate, isFalse);
      expect(config.maxSockets, equals(50));
    });

    test('copyWith creates new instance with updated values', () {
      final NamespaceName name1 = NamespaceName('/test1');
      final NamespaceName name2 = NamespaceName('/test2');
      final NamespaceConfig config1 = NamespaceConfig(name: name1);
      final NamespaceConfig config2 = config1.copyWith(name: name2, maxSockets: 100);

      expect(config2.name, equals(name2));
      expect(config2.maxSockets, equals(100));
      expect(config2.autoCreate, equals(config1.autoCreate));
    });

    test('withMiddleware adds middleware', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config1 = NamespaceConfig(name: name);
      final NamespaceConfig config2 = config1.withMiddleware(
        (final Object socket, final void Function(Object?) next) => next(null),
      );

      expect(config1.middleware, isEmpty);
      expect(config2.middleware, hasLength(1));
    });

    test('withMiddlewares adds multiple middleware', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config1 = NamespaceConfig(name: name);
      final List<dynamic Function(Object, void Function(Object?))> middlewares =
          <dynamic Function(Object, void Function(Object?))>[
        (final Object socket, final void Function(Object?) next) => next(null),
        (final Object socket, final void Function(Object?) next) => next(null),
      ];
      final NamespaceConfig config2 = config1.withMiddlewares(middlewares);

      expect(config1.middleware, isEmpty);
      expect(config2.middleware, hasLength(2));
    });

    test('equality works correctly', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config1 = NamespaceConfig(name: name, maxSockets: 100);
      final NamespaceConfig config2 = NamespaceConfig(name: name, maxSockets: 100);
      final NamespaceConfig config3 = NamespaceConfig(name: name, maxSockets: 50);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('hashCode is consistent', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config1 = NamespaceConfig(name: name, maxSockets: 100);
      final NamespaceConfig config2 = NamespaceConfig(name: name, maxSockets: 100);

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('toString includes all key information', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config = NamespaceConfig(
        name: name,
        autoCreate: false,
        maxSockets: 100,
      );

      final String str = config.toString();
      expect(str, contains('/test'));
      expect(str, contains('false'));
      expect(str, contains('100'));
    });
  });

  group('NamespaceConfigBuilder', () {
    test('builds config with name', () {
      final NamespaceConfig config = NamespaceConfigBuilder().name('/test').build();

      expect(config.name.value, equals('/test'));
      expect(config.autoCreate, isTrue);
    });

    test('builds config with all fields', () {
      final NamespaceConfig config = NamespaceConfigBuilder()
          .name('/test')
          .autoCreate(false)
          .maxSockets(100)
          .middleware(
            (final Object socket, final void Function(Object?) next) => next(null),
          )
          .build();

      expect(config.name.value, equals('/test'));
      expect(config.autoCreate, isFalse);
      expect(config.maxSockets, equals(100));
      expect(config.middleware, hasLength(1));
    });

    test('builds config with nameVo', () {
      final NamespaceName name = NamespaceName('/test');
      final NamespaceConfig config = NamespaceConfigBuilder().nameVo(name).build();

      expect(config.name, equals(name));
    });

    test('middleware adds single function', () {
      final NamespaceConfig config = NamespaceConfigBuilder()
          .name('/test')
          .middleware(
            (final Object socket, final void Function(Object?) next) => next(null),
          )
          .build();

      expect(config.middleware, hasLength(1));
    });

    test('middlewares adds multiple functions', () {
      final List<dynamic Function(Object, void Function(Object?))> middlewares =
          <dynamic Function(Object, void Function(Object?))>[
        (final Object socket, final void Function(Object?) next) => next(null),
        (final Object socket, final void Function(Object?) next) => next(null),
      ];

      final NamespaceConfig config = NamespaceConfigBuilder().name('/test').middlewares(middlewares).build();

      expect(config.middleware, hasLength(2));
    });

    test('maxSockets validates positive values', () {
      expect(
        () => NamespaceConfigBuilder().maxSockets(0),
        throwsArgumentError,
      );
      expect(
        () => NamespaceConfigBuilder().maxSockets(-1),
        throwsArgumentError,
      );
    });

    test('unlimitedSockets sets null maxSockets', () {
      final NamespaceConfig config = NamespaceConfigBuilder().name('/test').maxSockets(100).unlimitedSockets().build();

      expect(config.maxSockets, isNull);
    });

    test('throws StateError when name is missing', () {
      expect(
        () => NamespaceConfigBuilder().build(),
        throwsStateError,
      );
    });

    test('builds immutable middleware list', () {
      final NamespaceConfig config = NamespaceConfigBuilder()
          .name('/test')
          .middleware(
            (final Object socket, final void Function(Object?) next) => next(null),
          )
          .build();

      expect(
        () => config.middleware.add(
          (final Object socket, final void Function(Object?) next) => next(null),
        ),
        throwsUnsupportedError,
      );
    });

    test('builder methods are chainable', () {
      final NamespaceConfigBuilder builder = NamespaceConfigBuilder();
      final NamespaceConfigBuilder result = builder.name('/test').autoCreate(false).maxSockets(100);

      expect(result, same(builder));
    });

    test('builds multiple configs from same builder', () {
      final NamespaceConfigBuilder builder = NamespaceConfigBuilder().name('/test');

      final NamespaceConfig config1 = builder.build();
      final NamespaceConfig config2 = builder.maxSockets(100).build();

      expect(config1.name.value, equals('/test'));
      expect(config2.name.value, equals('/test'));
      expect(config1.maxSockets, isNull);
      expect(config2.maxSockets, equals(100));
    });
  });
}
