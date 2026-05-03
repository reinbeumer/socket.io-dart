// test/models/server_options_models_test.dart
//
// Tests for ServerOptionsModel and related classes
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.

import 'package:test/test.dart';
import '../../lib/src/models/server_options_models.dart';
import '../../lib/src/value_objects/timeout_duration_vo.dart';
import '../../lib/src/value_objects/transport_name_vo.dart';
import '../../lib/src/value_objects/url_path_vo.dart';

void main() {
  group('CookieConfig', () {
    test('should create enabled cookie with name', () {
      final CookieConfig config = CookieConfig.enabled('session');

      expect(config.isEnabled, isTrue);
      expect(config.name, equals('session'));
      expect(config.toCompatibility(), equals('session'));
    });

    test('should create disabled cookie', () {
      final CookieConfig config = CookieConfig.disabled();

      expect(config.isEnabled, isFalse);
      expect(config.name, isNull);
      expect(config.toCompatibility(), equals(false));
    });

    test('should create from dynamic string value', () {
      final CookieConfig config = CookieConfig.fromDynamic('io');

      expect(config.isEnabled, isTrue);
      expect(config.name, equals('io'));
    });

    test('should create disabled from false', () {
      final CookieConfig config = CookieConfig.fromDynamic(false);

      expect(config.isEnabled, isFalse);
      expect(config.name, isNull);
    });

    test('should create disabled from null', () {
      final CookieConfig config = CookieConfig.fromDynamic(null);

      expect(config.isEnabled, isFalse);
    });
  });

  group('CookiePathConfig', () {
    test('should create enabled cookie path', () {
      final CookiePathConfig config = CookiePathConfig.enabled('/api');

      expect(config.isEnabled, isTrue);
      expect(config.path, equals('/api'));
      expect(config.toCompatibility(), equals('/api'));
    });

    test('should create disabled cookie path', () {
      final CookiePathConfig config = CookiePathConfig.disabled();

      expect(config.isEnabled, isFalse);
      expect(config.path, isNull);
      expect(config.toCompatibility(), equals(false));
    });

    test('should create from dynamic string value', () {
      final CookiePathConfig config = CookiePathConfig.fromDynamic('/');

      expect(config.isEnabled, isTrue);
      expect(config.path, equals('/'));
    });

    test('should create disabled from false', () {
      final CookiePathConfig config = CookiePathConfig.fromDynamic(false);

      expect(config.isEnabled, isFalse);
    });
  });

  group('PerMessageDeflateConfig', () {
    test('should create with default threshold', () {
      const PerMessageDeflateConfig config = PerMessageDeflateConfig();

      expect(config.threshold, equals(1024));
      expect(config.additionalOptions, isEmpty);
    });

    test('should create with custom threshold', () {
      const PerMessageDeflateConfig config = PerMessageDeflateConfig(
        threshold: 2048,
      );

      expect(config.threshold, equals(2048));
    });

    test('should create from map', () {
      final PerMessageDeflateConfig config = PerMessageDeflateConfig.fromMap(<String, dynamic>{
        'threshold': 512,
        'memLevel': 8,
      });

      expect(config.threshold, equals(512));
      expect(config.additionalOptions['memLevel'], equals(8));
    });

    test('should handle null map', () {
      final PerMessageDeflateConfig config = PerMessageDeflateConfig.fromMap(null);

      expect(config.threshold, equals(1024));
      expect(config.additionalOptions, isEmpty);
    });

    test('should convert to map', () {
      const PerMessageDeflateConfig config = PerMessageDeflateConfig(
        threshold: 2048,
        additionalOptions: <String, Object?>{'level': 9},
      );

      final Map<String, dynamic> map = config.toMap();

      expect(map['threshold'], equals(2048));
      expect(map['level'], equals(9));
    });
  });

  group('HttpCompressionConfig', () {
    test('should create with default threshold', () {
      const HttpCompressionConfig config = HttpCompressionConfig();

      expect(config.threshold, equals(1024));
      expect(config.additionalOptions, isEmpty);
    });

    test('should create with custom threshold', () {
      const HttpCompressionConfig config = HttpCompressionConfig(
        threshold: 4096,
      );

      expect(config.threshold, equals(4096));
    });

    test('should create from map', () {
      final HttpCompressionConfig config = HttpCompressionConfig.fromMap(<String, dynamic>{
        'threshold': 256,
        'level': 6,
      });

      expect(config.threshold, equals(256));
      expect(config.additionalOptions['level'], equals(6));
    });

    test('should convert to map', () {
      const HttpCompressionConfig config = HttpCompressionConfig(
        threshold: 512,
        additionalOptions: <String, Object?>{'chunkSize': 8192},
      );

      final Map<String, dynamic> map = config.toMap();

      expect(map['threshold'], equals(512));
      expect(map['chunkSize'], equals(8192));
    });
  });

  group('ServerOptionsModel', () {
    test('should create with default values', () {
      final ServerOptionsModel options = ServerOptionsModel();

      expect(options.pingTimeout.inMilliseconds, equals(60000));
      expect(options.pingInterval.inMilliseconds, equals(25000));
      expect(options.upgradeTimeout.inMilliseconds, equals(10000));
      expect(options.maxHttpBufferSize, equals(10E7));
      expect(options.transports.length, equals(2));
      expect(options.allowUpgrades, isTrue);
      expect(options.cookieHttpOnly, isTrue);
      expect(options.path.value, equals('/engine.io'));
    });

    test('should create with custom values', () {
      final ServerOptionsModel options = ServerOptionsModel(
        pingTimeout: TimeoutDuration.milliseconds(30000),
        pingInterval: TimeoutDuration.milliseconds(10000),
        upgradeTimeout: TimeoutDuration.milliseconds(5000),
        maxHttpBufferSize: 5E7,
        transports: const <TransportName>[TransportName.websocket],
        allowUpgrades: false,
        cookieHttpOnly: false,
        path: UrlPath('/socket'),
      );

      expect(options.pingTimeout.inMilliseconds, equals(30000));
      expect(options.pingInterval.inMilliseconds, equals(10000));
      expect(options.upgradeTimeout.inMilliseconds, equals(5000));
      expect(options.maxHttpBufferSize, equals(5E7));
      expect(options.transports.length, equals(1));
      expect(options.transports.first, equals(TransportName.websocket));
      expect(options.allowUpgrades, isFalse);
      expect(options.cookieHttpOnly, isFalse);
      expect(options.path.value, equals('/socket'));
    });

    test('should create from map', () {
      final ServerOptionsModel options = ServerOptionsModel.fromMap(<String, dynamic>{
        'pingTimeout': 45000,
        'pingInterval': 20000,
        'upgradeTimeout': 8000,
        'transports': <String>['websocket'],
        'path': '/api/socket',
      });

      expect(options.pingTimeout.inMilliseconds, equals(45000));
      expect(options.pingInterval.inMilliseconds, equals(20000));
      expect(options.upgradeTimeout.inMilliseconds, equals(8000));
      expect(options.transports.length, equals(1));
      expect(options.path.value, equals('/api/socket'));
    });

    test('should handle null map in fromMap', () {
      final ServerOptionsModel options = ServerOptionsModel.fromMap(null);

      expect(options.pingTimeout.inMilliseconds, equals(60000));
      expect(options.path.value, equals('/engine.io'));
    });

    test('should convert to map', () {
      final ServerOptionsModel options = ServerOptionsModel(
        pingTimeout: TimeoutDuration.milliseconds(30000),
        transports: const <TransportName>[TransportName.polling],
        path: UrlPath('/custom'),
      );

      final Map<String, dynamic> map = options.toMap();

      expect(map['pingTimeout'], equals(30000));
      expect(map['transports'], equals(<String>['polling']));
      expect(map['path'], equals('/custom'));
    });

    test('should handle cookie configuration', () {
      final ServerOptionsModel options = ServerOptionsModel(
        cookie: const EnabledCookie('custom_session'),
      );

      final Map<String, dynamic> map = options.toMap();
      expect(map['cookie'], equals('custom_session'));
    });

    test('should handle disabled cookie', () {
      final ServerOptionsModel options = ServerOptionsModel(
        cookie: const DisabledCookie(),
      );

      final Map<String, dynamic> map = options.toMap();
      expect(map['cookie'], equals(false));
    });

    test('should handle perMessageDeflate configuration', () {
      final ServerOptionsModel options = ServerOptionsModel(
        perMessageDeflate: const PerMessageDeflateConfig(threshold: 2048),
      );

      final Map<String, dynamic> map = options.toMap();
      expect(map['perMessageDeflate']['threshold'], equals(2048));
    });

    test('should handle httpCompression configuration', () {
      final ServerOptionsModel options = ServerOptionsModel(
        httpCompression: const HttpCompressionConfig(threshold: 4096),
      );

      final Map<String, dynamic> map = options.toMap();
      expect(map['httpCompression']['threshold'], equals(4096));
    });
  });

  group('AttachmentOptionsModel', () {
    test('should create with default path', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel();

      expect(options.path.value, equals('/engine.io'));
      expect(options.custom, isEmpty);
    });

    test('should create with custom path', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel(
        path: UrlPath('/api'),
      );

      expect(options.path.value, equals('/api'));
    });

    test('should create with custom options', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel(
        path: UrlPath('/socket'),
        custom: const <String, Object?>{'key': 'value'},
      );

      expect(options.path.value, equals('/socket'));
      expect(options.custom['key'], equals('value'));
    });

    test('should create from map', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel.fromMap(<String, dynamic>{
        'path': '/custom',
        'extra': 'data',
      });

      expect(options.path.value, equals('/custom'));
      expect(options.custom['extra'], equals('data'));
    });

    test('should handle null map', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel.fromMap(null);

      expect(options.path.value, equals('/engine.io'));
    });

    test('should convert to map', () {
      final AttachmentOptionsModel options = AttachmentOptionsModel(
        path: UrlPath('/socket'),
        custom: const <String, Object?>{'key': 'value'},
      );

      final Map<String, dynamic> map = options.toMap();

      expect(map['path'], equals('/socket'));
      expect(map['key'], equals('value'));
    });
  });
}
