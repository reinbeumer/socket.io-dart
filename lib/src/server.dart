/*
server.dart

Purpose:

Description:

History:
   22/02/2017, Created by jumperchen

Copyright (C) 2017 Potix Corporation. All Rights Reserved.
*/
import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:socket_io_common/socket_io_common.dart';
import 'package:stream/stream.dart';

import 'client.dart';
import 'engine/engine.dart';
import 'models/callbacks_models.dart';
import 'namespace.dart';
import 'socket.dart';
import 'util/async_utils.dart';
import 'util/event_emitter.dart';

/// Socket.IO client source.
/// Old settings for backwards compatibility
Map<String, String> oldSettings = <String, String>{
  'transports': 'transports',
  'heartbeat timeout': 'pingTimeout',
  'heartbeat interval': 'pingInterval',
  'destroy buffer size': 'maxHttpBufferSize'
};

final Logger _logger = Logger('socket_io:Server');

/// A Socket.IO server for real-time bidirectional communication.
///
/// The [Server] class is the main entry point for creating a Socket.IO server.
/// It manages namespaces, handles client connections, and configures transport options.
///
/// ## Basic Usage
///
/// ```dart
/// // Create a server
/// final io = Server();
///
/// // Listen for connections
/// io.on('connection', (socket) {
///   print('Client connected: ${socket.id}');
///
///   socket.on('message', (data) {
///     print('Received: $data');
///     socket.emit('response', ['Message received']);
///   });
/// });
///
/// // Start listening on a port
/// io.listen(3000);
/// ```
///
/// ## With Options
///
/// ```dart
/// final io = Server(options: {
///   'path': '/socket.io',
///   'pingTimeout': 60000,
///   'pingInterval': 25000,
///   'transports': ['websocket', 'polling'],
/// });
/// ```
///
/// ## Multiple Namespaces
///
/// ```dart
/// // Default namespace
/// io.on('connection', (socket) {
///   print('Connected to default namespace');
/// });
///
/// // Custom namespace
/// final chat = io.of('/chat');
/// chat.on('connection', (socket) {
///   print('Connected to /chat namespace');
/// });
/// ```
///
/// See also:
/// * [Namespace] for namespace-specific configuration
/// * [Socket] for individual client connections
class Server {
  // Namespaces
  Map<String, Namespace> nsps = <String, Namespace>{};
  late Namespace sockets;
  String _origins = '*:*';
  bool? _serveClient;
  String? _path;
  String _adapter = 'default';
  StreamServer? httpServer;
  Engine? engine;
  Encoder encoder = Encoder();
  Future<bool>? _ready;

  /// Indicates whether the server is ready to accept connections.
  ///
  /// Returns a [Future] that completes with `true` when the server
  /// is fully initialized and ready to accept client connections.
  ///
  /// Example:
  /// ```dart
  /// final io = Server();
  /// await io.ready;  // Wait for server to be ready
  /// print('Server is ready on port ${io.port}');
  /// ```
  Future<bool> get ready => _ready ?? Future<bool>.value(false);

  /// The port number on which the server is listening.
  ///
  /// Returns `null` if the server is not yet listening on any port.
  ///
  /// Example:
  /// ```dart
  /// final io = Server();
  /// io.listen(3000);
  /// print('Listening on port ${io.port}');  // Output: Listening on port 3000
  /// ```
  int? get port {
    if (httpServer == null || httpServer!.channels.isEmpty) {
      return null;
    }
    return httpServer!.channels[0].port;
  }

  /// Creates a new Socket.IO server instance.
  ///
  /// The [server] parameter is optional and can be a [StreamServer] to attach to.
  /// The [options] parameter configures server behavior.
  ///
  /// ## Available Options
  ///
  /// * `path` (String): The path to capture ('/' by default, '/socket.io')
  /// * `serveClient` (bool): Whether to serve the client files (true by default)
  /// * `adapter` (String): The adapter to use ('default' for in-memory)
  /// * `origins` (String): Allowed origins ('*:*' by default)
  /// * `pingTimeout` (int): How many ms without a pong packet to consider the connection closed (60000)
  /// * `pingInterval` (int): How many ms before sending a new ping packet (25000)
  /// * `transports` (List<String>): Transports to allow (['websocket', 'polling'])
  ///
  /// ## Examples
  ///
  /// ### Basic server
  /// ```dart
  /// final io = Server();
  /// io.listen(3000);
  /// ```
  ///
  /// ### With existing HTTP server
  /// ```dart
  /// final httpServer = await StreamServer.bind('localhost', 3000);
  /// final io = Server(server: httpServer);
  /// ```
  ///
  /// ### With custom options
  /// ```dart
  /// final io = Server(options: {
  ///   'path': '/my-socket',
  ///   'pingTimeout': 120000,
  ///   'pingInterval': 30000,
  ///   'transports': ['websocket'],  // WebSocket only
  /// });
  /// ```
  Server({final StreamServer? server, Map<String, dynamic>? options}) {
    options ??= <String, dynamic>{};
    path(options.containsKey('path') ? options['path'] as String? : '/socket.io');
    serveClient(false != options['serveClient']);
    adapter = options.containsKey('adapter') ? options['adapter'] as String : 'default';
    origins(options.containsKey('origins') ? options['origins'] as String? : '*:*');
    sockets = of('/');
    if (server != null) {
      _ready = Future<bool>(() async {
        await attach(server, options);
        return true;
      });
    } else {
      _ready = Future<bool>.value(true);
    }
  }

  /// Server request verification function, that checks for allowed origins
  ///
  /// @param {http.IncomingMessage} request
  /// @return {Future<bool>} true if the request is allowed, false otherwise
  Future<bool> checkRequest(final HttpRequest req) async {
    String? origin = req.headers.value('origin') ?? req.headers.value('referer');

    // file:// URLs produce a null Origin which can't be authorized via echo-back
    if (origin == null || origin.isEmpty) {
      origin = '*';
    }

    if (origin.isNotEmpty && _origins.contains('*:*')) {
      return true;
    }

    if (origin.isNotEmpty) {
      try {
        final Uri parts = Uri.parse(origin);
        final int port = parts.port;
        final bool ok = _origins.contains('${parts.host}:$port') ||
            _origins.contains('${parts.host}:*') ||
            _origins.contains('*:$port');

        return ok;
      } catch (ex) {
        _logger.severe(ex);
      }
    }

    return false;
  }

  /// Wrapper to convert async checkRequest to callback-based for engine.io
  bool _checkRequestWrapper(final dynamic req, final dynamic Function(dynamic, bool) callback) {
    if (req is HttpRequest) {
      // Fire and forget - the callback will be called asynchronously
      unawaited(checkRequest(req).then((final bool result) {
        callback(null, result);
      }).catchError((final dynamic error) {
        callback(error, false);
      }));
      return true; // Indicate that callback will be called asynchronously
    }
    callback(null, false);
    return false;
  }

  /// Sets/gets whether client code is being served.
  ///
  /// @param {Boolean} whether to serve client code
  /// @return {Server|Boolean} self when setting or value when getting
  /// @api public
  Object serveClient([final bool? v]) {
    if (v == null) {
      return _serveClient ?? false;
    }

    _serveClient = v;
    return this;
  }

  /// Backwards compatiblity.
  ///
  /// @api public
  Server set(final String key, [final Object? val]) {
    if ('authorization' == key && val != null) {
      use((final Object socket, final MiddlewareNext next) {
        (val as Function)((socket as Socket).request, (final Object? err, final bool authorized) {
          if (err != null) {
            return next(Exception(err));
          }
          if (authorized != true) {
            return next(Exception('Not authorized'));
          }

          next(null);
        });
      });
    } else if ('origins' == key && val != null) {
      origins(val as String?);
    } else if ('resource' == key) {
      path(val as String?);
    } else if (oldSettings.containsKey(key) && engine != null) {
      // Note: Engine type needs to be checked for containsKey method
      _logger.fine('Setting engine property ${oldSettings[key]} to $val');
    } else {
      _logger.severe('Option $key is not valid. Please refer to the README.');
    }

    return this;
  }

  /// Sets the client serving path.
  ///
  /// @param {String} pathname
  /// @return {Server|String} self when setting or value when getting
  /// @api public
  Object path([final String? v]) {
    if (v == null || v.isEmpty) return _path ?? '';
    _path = v.replaceFirst(RegExp(r'/$'), '');
    return this;
  }

  /// Sets the adapter for rooms.
  ///
  /// @param {Adapter} pathname
  /// @return {Server|Adapter} self when setting or value when getting
  /// @api public
  String get adapter => _adapter;

  set adapter(final String v) {
    _adapter = v;
    if (nsps.isNotEmpty) {
      nsps.forEach((final String i, final Namespace nsp) {
        nsp.initAdapter();
      });
    }
  }

  /// Sets the allowed origins for requests.
  ///
  /// @param {String} origins
  /// @return {Server|String} self when setting or value when getting
  /// @api public
  Object origins([final String? v]) {
    if (v == null || v.isEmpty) return _origins;

    _origins = v.isNotEmpty ? v : '*:*';
    return this;
  }

  /// Attaches socket.io to a server or port.
  ///
  /// @param {http.Server|Number} server or port
  /// @param {Object} options passed to engine.io
  /// @return {Server} self
  /// @api public
  Future<void> listen(final Object srv, [final Map<String, dynamic>? opts]) async {
    if (srv is StreamServer) {
      await attach(srv, opts);
    } else if (srv is num) {
      await attachToPort(srv.toInt(), opts);
    } else if (srv is String && int.tryParse(srv) != null) {
      await attachToPort(int.parse(srv), opts);
    } else {
      throw ArgumentError('Invalid server type. Expected StreamServer, int, or string representation of port number.');
    }
  }

  /// Attaches socket.io to a StreamServer instance.
  ///
  /// @param {StreamServer} server instance
  /// @param {Object} options passed to engine.io
  /// @return {Server} self
  /// @api public
  Future<Server> attach(final StreamServer srv, [Map<String, dynamic>? opts]) async {
    opts ??= <String, dynamic>{};

    // set engine.io path to `/socket.io`
    if (!opts.containsKey('path')) {
      opts['path'] = path();
    }
    // set origins verification
    opts['allowRequest'] = _checkRequestWrapper;

    _logger.fine('creating engine.io instance with opts $opts');
    // initialize engine
    engine = Engine.attach(srv, opts);

    // Export http server
    httpServer = srv;

    // bind to engine events
    bind(engine!);

    return this;
  }

  /// Attaches socket.io to a port number by creating a new StreamServer.
  ///
  /// @param {int} port number
  /// @param {Object} options passed to engine.io
  /// @return {Server} self
  /// @api public
  Future<Server> attachToPort(final int port, [Map<String, dynamic>? opts]) async {
    opts ??= <String, dynamic>{};

    // set engine.io path to `/socket.io`
    if (!opts.containsKey('path')) {
      opts['path'] = path();
    }
    // set origins verification
    opts['allowRequest'] = _checkRequestWrapper;

    _logger.fine('creating http server and binding to $port');
    final StreamServer server = StreamServer();
    await server.start(port: port);

    _logger.fine('creating engine.io instance with opts $opts');
    // initialize engine
    engine = Engine.attach(server, opts);

    // Export http server
    httpServer = server;

    // bind to engine events
    bind(engine!);

    return this;
  }

  /// Attaches the static file serving.
  ///
  /// @param {Function|http.Server} http server
  /// @api private
  /// @todo Include better way to serve files
//    attachServe(srv){

  /// Binds socket.io to an engine.io instance.
  ///
  /// @param {engine.Server} engine.io (or compatible) server
  /// @return {Server} self
  /// @api public
  Server bind(final Engine engine) {
    this.engine = engine;
    this.engine!.on('connection', onconnection);
    return this;
  }

  /// Called with each incoming transport connection.
  ///
  /// @param {engine.Socket} socket
  /// @return {Server} self
  /// @api public
  Server onconnection(final dynamic conn) {
    _logger.fine('incoming connection with id ${conn.toString()}');
    Client(this, conn).connect('/');
    return this;
  }

  /// Looks up a namespace.
  ///
  /// @param {String} nsp name
  /// @param {Function} optional, nsp `connection` ev handler
  /// @api public
  // Namespace of(Object name, [Function? fn]) {
  //   if (name is! String) {
  //     fn = name as Function?;
  //     name = '/';
  //   }
  //   String nameStr = name.toString();
  //   if (nameStr[0] != '/') {
  //     nameStr = '/$nameStr';
  //   }
  //
  //   if (!nsps.containsKey(nameStr)) {
  //     _logger.fine('initializing namespace $nameStr');
  //     final Namespace nsp = Namespace(this, nameStr);
  //     nsps[nameStr] = nsp;
  //   }
  //   if (fn != null) {
  //     nsps[nameStr]!.on('connect', (final dynamic socket) => fn!(socket));
  //   }
  //   return nsps[nameStr]!;
  // }
  Namespace of(Object name) {
    final Object rawName = name is String ? name : '/';
    String nameStr = rawName.toString();
    if (nameStr[0] != '/') {
      nameStr = '/$nameStr';
    }

    if (!nsps.containsKey(nameStr)) {
      _logger.fine('initializing namespace $nameStr');
      final Namespace nsp = Namespace(this, nameStr);
      nsps[nameStr] = nsp;
    }
    return nsps[nameStr]!;
  }

  /// Closes server connection
  ///
  /// @return a Future that resolves when the httpServer is closed
  /// @api public
  Future<void> close() async {
    nsps['/']!.sockets.toList(growable: false).forEach((final Socket socket) {
      socket.onclose();
    });

    engine?.close();

    if (httpServer != null) {
      await httpServer!.stop();
    }

    _ready = null;
  }

  // redirect to sockets method
  Namespace to(final String data) => sockets.to(data);
  Namespace use(final MiddlewareCallback middleware) => sockets.use(middleware);
  void send(final Object data) => sockets.send(data);
  Namespace write(final Object data) => sockets.write(data);
  Namespace clients(final List<String>? rooms) => sockets.clients(rooms);
  Namespace compress(final bool compress) => sockets.compress(compress);

  // emitter
  void emit(final String event, final Object? data) => sockets.emit(event, data);

  // Special overload for connection events that pass Socket objects
  void onConnection(final void Function(Socket) handler) =>
      sockets.on('connection', (final dynamic data) => handler(data as Socket));

  // General event handler for other events
  void on(final String event, final EventHandler<SocketIOEventData> handler) {
    if (event == 'connection') {
      throw ArgumentError('Use onConnection() method for connection events instead of on()');
    }
    sockets.on(event, handler);
  }

  void once(final String event, final EventHandler<SocketIOEventData> handler) => sockets.once(event, handler);
  void off(final String event, final EventHandler<SocketIOEventData> handler) => sockets.off(event, handler);
}
