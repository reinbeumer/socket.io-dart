// server
//
// Purpose:
//
// Description:
//
// History:
//    17/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io' hide Socket;

import 'package:logging/logging.dart';
import 'package:stream/stream.dart';
import 'package:uuid/uuid.dart';

import '../models/server_options_models.dart';
import '../value_objects/timeout_duration_vo.dart';
import '../value_objects/transport_name_vo.dart';
import '../value_objects/url_path_vo.dart';
import 'connect.dart';
import 'engine.dart';
import 'socket.dart';
import 'transport/transports.dart';

/// Server constructor.
///
/// @param {Object} options
/// @api public
class ServerErrors {
  static const int UNKNOWN_TRANSPORT = 0;
  static const int UNKNOWN_SID = 1;
  static const int BAD_HANDSHAKE_METHOD = 2;
  static const int BAD_REQUEST = 3;
  static const int FORBIDDEN = 4;
}

const Map<int, String> ServerErrorMessages = <int, String>{
  0: 'Transport unknown',
  1: 'Session ID unknown',
  2: 'Bad handshake method',
  3: 'Bad request',
  4: 'Forbidden'
};

class Server extends Engine {
  static final Logger _logger = Logger('socket_io:engine.Server');
  Map<String, Socket> clients = <String, Socket>{};
  int clientsCount = 0;
  late TimeoutDuration pingTimeout;
  late TimeoutDuration pingInterval;
  late TimeoutDuration upgradeTimeout;
  late double maxHttpBufferSize;
  late List<TransportName> transports;
  late bool allowUpgrades;
  AllowRequestCallback? allowRequest;
  late CookieConfig cookie;
  late CookiePathConfig cookiePath;
  late bool cookieHttpOnly;
  late PerMessageDeflateConfig perMessageDeflate;
  late HttpCompressionConfig httpCompression;
  Object? initialPacket;
  late UrlPath path;
  final Uuid _uuid = const Uuid();

  Server(final ServerOptionsModel options) {
    pingTimeout = options.pingTimeout;
    pingInterval = options.pingInterval;
    upgradeTimeout = options.upgradeTimeout;
    maxHttpBufferSize = options.maxHttpBufferSize;
    transports = List<TransportName>.from(options.transports);
    allowUpgrades = options.allowUpgrades;
    allowRequest = options.allowRequest;
    cookie = options.cookie;
    cookiePath = options.cookiePath;
    cookieHttpOnly = options.cookieHttpOnly;
    perMessageDeflate = options.perMessageDeflate;
    httpCompression = options.httpCompression;
    initialPacket = options.initialPacket;
    path = options.path;
    _init();
  }

  /// Create from Map (legacy support)
  factory Server.fromMap(final Map<String, dynamic>? opts) => Server(ServerOptionsModel.fromMap(opts));

  /// Initialize websocket server
  ///
  /// @api private

  void _init() {
//  if (this.transports.indexOf('websocket') == -1) return;

//  if (this.ws) this.ws.close();
//
//  var wsModule;
//  try {
//    wsModule = require(this.wsEngine);
//  } catch (ex) {
//    this.wsEngine = 'ws';
//    // keep require('ws') as separate expression for packers (browserify, etc)
//    wsModule = require('ws');
//  }
//  this.ws = new wsModule.Server({
//    noServer: true,
//    clientTracking: false,
//    perMessageDeflate: this.perMessageDeflate,
//    maxPayload: this.maxHttpBufferSize
//  });
  }

  /// Returns a list of available transports for upgrade given a certain transport.
  ///
  /// @return {Array}
  /// @api public

  List<String> upgrades(final String transport) {
    if (!allowUpgrades) return List<String>.empty();
    return Transports.upgradesTo(transport);
  }

  /// Verifies a request.
  ///
  /// @param {http.IncomingMessage}
  /// @return {Boolean} whether the request is valid
  /// @api private
  void verify(final SocketConnect connect, final bool upgrade, final void Function(Object?, bool) fn) {
    // transport check
    final HttpRequest req = connect.request;
    final String? transport = req.uri.queryParameters['transport'];
    final bool transportSupported =
        transport != null && transports.any((final TransportName t) => t.value == transport);
    if (!transportSupported) {
      _logger.fine('unknown transport "$transport"');
      return fn(ServerErrors.UNKNOWN_TRANSPORT, false);
    }

    // sid check
    final String? sid = req.uri.queryParameters['sid'];
    if (sid != null) {
      if (!clients.containsKey(sid)) {
        return fn(ServerErrors.UNKNOWN_SID, false);
      }
      final Socket? client = clients[sid];
      if (!upgrade && client != null && client.transport.name != transport) {
        _logger.fine('bad request: unexpected transport without upgrade');
        return fn(ServerErrors.BAD_REQUEST, false);
      }
    } else {
      if ('OPTIONS' == req.method) {
        return fn(null, true);
      }

      // handshake is GET only
      if ('GET' != req.method) {
        return fn(ServerErrors.BAD_HANDSHAKE_METHOD, false);
      }
      if (allowRequest == null) return fn(null, true);
      allowRequest!(req, fn);
      return;
    }

    fn(null, true);
  }

  /// Closes all clients.
  ///
  /// @api public
  @override
  void close() {
    _logger.fine('closing all open clients');
    for (final String key in clients.keys.toList(growable: false)) {
      clients[key]?.close(true);
    }
//  if (this.ws) {
//    _logger.fine('closing webSocketServer');
//    this.ws.close();
//    // don't delete this.ws because it can be used again if the http server starts listening again
//  }
  }

  /// Handles an Engine.IO HTTP request.
  ///
  /// @param {http.IncomingMessage} request
  /// @param {http.ServerResponse|http.OutgoingMessage} response
  /// @api public
  void handleRequest(final SocketConnect connect) {
    final HttpRequest req = connect.request;
    _logger.fine('handling ${req.method} http request ${req.uri.path}');

    final Server self = this;
    verify(connect, false, (final Object? err, final bool success) {
      if (!success) {
        sendErrorMessage(req, err);
        return;
      }

      final String? sid = req.uri.queryParameters['sid'];
      if (sid != null) {
        _logger.fine('setting new request for existing client');
        final Socket? client = self.clients[sid];
        client?.transport.onRequest(connect);
      } else {
        self.handshake(req.uri.queryParameters['transport'] as String, connect);
      }
    });
  }

  /// Sends an Engine.IO Error Message
  ///
  /// @param {http.ServerResponse} response
  /// @param {code} error code
  /// @api private
  static void sendErrorMessage(final HttpRequest req, final Object? code) {
    final HttpResponse res = req.response;
    final bool isForbidden = !ServerErrorMessages.containsKey(code);
    if (isForbidden) {
      res
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(json.encode(<String, dynamic>{
          'code': ServerErrors.FORBIDDEN,
          'message': code ?? ServerErrorMessages[ServerErrors.FORBIDDEN]
        }));
      unawaited(res.close());
      return;
    }
    if (req.headers.value('origin') != null) {
      res.headers.add('Access-Control-Allow-Credentials', 'true');
      res.headers.add('Access-Control-Allow-Origin', req.headers.value('origin')!);
    } else {
      res.headers.add('Access-Control-Allow-Origin', '*');
    }
    res
      ..statusCode = HttpStatus.badRequest
      ..write(json.encode(<String, dynamic>{'code': code, 'message': ServerErrorMessages[code]}));
    unawaited(res.close());
  }

  /// generate a socket id.
  /// Overwrite this method to generate your custom socket id
  ///
  /// @param {Object} request object
  /// @api public
  String generateId(final SocketConnect connect) => _uuid.v1().replaceAll('-', '');

  /// Handshakes a new client.
  ///
  /// @param {String} transport name
  /// @param {Object} request object
  /// @api private
  void handshake(final String transportName, final SocketConnect connect) {
    final String id = generateId(connect);

    _logger.fine('handshaking client $id');
    late Transport transport;
    final HttpRequest req = connect.request;
    try {
      transport = Transports.newInstance(transportName, connect);
      if ('polling' == transportName) {
        transport
          ..maxHttpBufferSize = maxHttpBufferSize
          ..httpCompression = httpCompression.toMap();
      } else if ('websocket' == transportName) {
        transport.perMessageDeflate = perMessageDeflate.toMap();
      }

      if (req.uri.hasQuery && req.uri.queryParameters.containsKey('b64')) {
        transport.supportsBinary = false;
      } else {
        transport.supportsBinary = true;
      }
    } catch (e) {
      sendErrorMessage(req, ServerErrors.BAD_REQUEST);
      return;
    }
    final Socket socket = Socket(id, this, transport, connect);

    if (cookie.isEnabled && cookie.name != null) {
      transport.on('headers', (final dynamic headers) {
        final StringBuffer cookieValue = StringBuffer('${cookie.name}=${Uri.encodeComponent(id)}');
        if (cookiePath.isEnabled && cookiePath.path != null) {
          cookieValue.write('; Path=${cookiePath.path}');
          if (cookieHttpOnly) {
            cookieValue.write('; HttpOnly');
          }
        }
        headers['Set-Cookie'] = cookieValue.toString();
      });
    }

    transport.onRequest(connect);

    clients[id] = socket;
    clientsCount++;

    socket.once('close', (final _) {
      clients.remove(id);
      clientsCount--;
    });

    emit('connection', socket);
  }

  /// Handles an Engine.IO HTTP Upgrade.
  ///
  /// @api public
  void handleUpgrade(final SocketConnect connect) {
    verify(connect, true, (final Object? err, final bool success) async {
      if (!success) {
        await abortConnection(connect, err);
        return;
      }
      await onWebSocket(connect);
    });
  }

  /// Called upon a ws.io connection.
  ///
  /// @param {ws.Socket} websocket
  /// @api private
  Future<void> onWebSocket(final SocketConnect connect) async {
    if (connect.request.connectionInfo == null) {
      _logger.fine('WebSocket connection closed: ${connect.request.uri.path}');
      return;
    }
    // get client id
    final String? id = connect.request.uri.queryParameters['sid'];

    if (id != null) {
      final Socket? client = clients[id];
      if (client == null) {
        _logger.fine('upgrade attempt for closed client');
        await connect.websocket?.close();
      } else if (client.upgrading == true) {
        _logger.fine('transport has already been trying to upgrade');
        if (connect.websocket != null) {
          await connect.websocket!.close();
        }
      } else if (client.upgraded == true) {
        _logger.fine('transport had already been upgraded');
        if (connect.websocket != null) {
          await connect.websocket!.close();
        }
      } else {
        _logger.fine('upgrading existing transport');
        final HttpRequest req = connect.request;
        final Transport transport = Transports.newInstance(req.uri.queryParameters['transport'] as String, connect);
        final String? b64 = req.uri.queryParameters['b64'];
        if (b64 == '1' || b64 == 'true') {
          transport.supportsBinary = false;
        } else {
          transport.supportsBinary = true;
        }
        transport.perMessageDeflate = perMessageDeflate.toMap();
        client.maybeUpgrade(transport);
      }
    } else {
      handshake(connect.request.uri.queryParameters['transport'] as String, connect);
    }
  }

  /// Captures upgrade requests for a http.Server.
  ///
  /// @param {http.Server} server
  /// @param {AttachmentOptionsModel} options
  /// @api public
  void attachTo(final StreamServer server, final Map<String, dynamic>? options) {
    final AttachmentOptionsModel attachOptions = AttachmentOptionsModel.fromMap(options);
    String path = attachOptions.path.value.replaceFirst(RegExp(r'/$'), '');

    // normalize path
    path += '/';

    // cache and clean up listeners
    server.map('$path.*', (final HttpConnect connect) async {
      final HttpRequest req = connect.request;

      _logger.fine('intercepting request for path "$path"');
      if (WebSocketTransformer.isUpgradeRequest(req) &&
          transports.any((final TransportName t) => t == TransportName.websocket)) {
//          print('init websocket... ${req.uri}');
        final WebSocket socket = await WebSocketTransformer.upgrade(req);
        final SocketConnect socketConnect = SocketConnect.fromWebSocket(connect, socket);
        socketConnect.dataset['options'] = attachOptions.toMap();
        handleUpgrade(socketConnect);
        return socketConnect.done;
      } else {
        final SocketConnect socketConnect = SocketConnect(connect);
        socketConnect.dataset['options'] = attachOptions.toMap();
        handleRequest(socketConnect);
        return socketConnect.done;
      }
    }, preceding: true);
  }

  /// Closes the connection
  ///
  /// @param {net.Socket} socket
  /// @param {code} error code
  /// @api private
  static Future<void> abortConnection(final SocketConnect connect, final Object? code) async {
    final WebSocket? socket = connect.websocket;
    if (socket?.readyState == HttpStatus.ok) {
      final String message = ServerErrorMessages.containsKey(code) ? ServerErrorMessages[code]! : code.toString();
      final int length = utf8.encode(message).length;
      socket!.add(
          'HTTP/1.1 400 Bad Request\r\nConnection: close\r\nContent-type: text/html\r\nContent-Length: $length\r\n\r\n$message');
    }
    if (socket != null) {
      await socket.close();
    }
  }
}
