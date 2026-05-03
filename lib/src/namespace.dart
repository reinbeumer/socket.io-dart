// ignore_for_file: implementation_imports
// namespace.dart
//
// Purpose:
//
// Description:
//
// History:
//    17/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:socket_io_common/src/parser/parser.dart';
import 'adapter.dart';
import 'client.dart';
import 'models/callbacks_models.dart';
import 'server.dart';
import 'socket.dart';
import 'util/event_emitter.dart';
import 'value_objects/event_name_vo.dart';
import 'value_objects/query_parameters_vo.dart';

/// A Socket.IO namespace for organizing socket connections.
///
/// Namespaces allow you to split the logic of your application over a single
/// shared connection. This is useful for implementing multiplexed applications
/// or for authorization.
///
/// ## Basic Usage
///
/// ```dart
/// // Access default namespace
/// io.on('connection', (socket) {
///   print('Connected to default namespace');
/// });
///
/// // Create custom namespace
/// final chat = io.of('/chat');
/// chat.on('connection', (socket) {
///   print('Connected to /chat');
///   socket.emit('welcome', ['Welcome to chat!']);
/// });
/// ```
///
/// ## With Middleware
///
/// ```dart
/// final admin = io.of('/admin');
///
/// // Add authentication middleware
/// admin.use((socket, next) {
///   final token = socket.handshake?['auth']?['token'];
///   if (isValidToken(token)) {
///     next(null);  // Allow connection
///   } else {
///     next('Authentication failed');  // Reject
///   }
/// });
///
/// admin.on('connection', (socket) {
///   print('Authenticated admin connected');
/// });
/// ```
///
/// ## Broadcasting
///
/// ```dart
/// // Broadcast to all clients in namespace
/// chat.emit('announcement', ['Server message']);
///
/// // Broadcast to specific room
/// chat.to('room1').emit('message', ['Room message']);
/// ```
///
/// See also:
/// * [Server.of] to create or access namespaces
/// * [Socket] for individual client connections within a namespace
class Namespace extends EventEmitter {
  String name;
  Server server;
  List<Socket> sockets = <Socket>[];
  Map<String, Socket> connected = <String, Socket>{};
  List<MiddlewareCallback> fns = <MiddlewareCallback>[];
  int ids = 0;
  List<String> rooms = <String>[];
  Map<String, bool> flags = <String, bool>{};
  late Adapter adapter;
  final Logger _logger = Logger('socket_io:Namespace');

  /// Namespace constructor.
  ///
  /// @param {Server} server instance
  /// @param {Socket} name
  /// @api private
  Namespace(this.server, this.name) {
    initAdapter();
  }

  /// Initializes the `Adapter` for this nsp.
  /// Run upon changing adapter by `Server#adapter`
  /// in addition to the constructor.
  ///
  /// @api private
  void initAdapter() {
    adapter = Adapter.newInstance(server.adapter, this);
  }

  /// Sets up namespace middleware.
  ///
  /// @return {Namespace} self
  /// @api public
  Namespace use(final MiddlewareCallback fn) {
    fns.add(fn);
    return this;
  }

  /// Executes the middleware for an incoming client.
  ///
  /// @param {Socket} socket that will get added
  /// @param {Function} last fn call in the middleware
  /// @api private
  void run(final Socket socket, final MiddlewareNext fn) {
    final List<MiddlewareCallback> fns = this.fns.sublist(0);
    if (fns.isEmpty) {
      fn(null);
      return;
    }

    run0(0, fns, socket, fn);
  }

  static void run0(
    final int index,
    final List<MiddlewareCallback> fns,
    final Socket socket,
    final MiddlewareNext fn,
  ) {
    fns[index](socket, (final Object? err) {
      // upon error, short-circuit
      if (err != null) {
        fn(err);
        return;
      }

      // if no middleware left, summon callback
      if (fns.length <= index + 1) {
        fn(null);
        return;
      }

      // go on to next
      run0(index + 1, fns, socket, fn);
      return;
    });
  }

  /// Targets a room when emitting.
  ///
  /// @param {String} name
  /// Targets a room when emitting.
  ///
  /// @param {String} name
  /// @return {Namespace} self
  /// @api public
  Namespace to(final String name) {
    rooms = rooms.isNotEmpty == true ? rooms : <String>[];
    if (!rooms.contains(name)) rooms.add(name);
    return this;
  }

  /// Adds a new client.
  ///
  /// @return {Socket}
  /// @api private
  Socket add(final Client client, final Map<String, dynamic>? query, final Function? fn) {
    _logger.fine('adding socket to nsp $name');
    final Socket socket = Socket(this, client, query);
    final Namespace self = this;
    run(socket, (final Object? err) {
      // don't use Timer.run() here
      scheduleMicrotask(() {
        if ('open' == client.conn.readyState) {
          if (err != null) return socket.error(err);

          // track socket
          self.sockets.add(socket);

          // it's paramount that the internal `onconnect` logic
          // fires before user-set events to prevent state order
          // violations (such as a disconnection before the connection
          // logic is complete)
          socket.onconnect();
          if (fn != null) fn(socket);

          // fire user-set events
          self
            ..emit('connect', socket)
            ..emit('connection', socket);
        } else {
          _logger.fine('next called after client was closed - ignoring socket');
        }
      });
    });
    return socket;
  }

  /// Adds a new client using typed QueryParameters.
  ///
  /// @return {Socket}
  /// @api public
  Socket addTyped(final Client client, final QueryParameters? query, final ConnectionCallback? fn) {
    _logger.fine('adding socket to nsp $name');
    final Socket socket = Socket.typed(this, client, query);
    final Namespace self = this;
    run(socket, (final Object? err) {
      // don't use Timer.run() here
      scheduleMicrotask(() {
        if ('open' == client.conn.readyState) {
          if (err != null) return socket.error(err);

          // track socket
          self.sockets.add(socket);

          // it's paramount that the internal `onconnect` logic
          // fires before user-set events to prevent state order
          // violations (such as a disconnection before the connection
          // logic is complete)
          socket.onconnect();
          if (fn != null) fn(socket);

          // fire user-set events
          self
            ..emit('connect', socket)
            ..emit('connection', socket);
        } else {
          _logger.fine('next called after client was closed - ignoring socket');
        }
      });
    });
    return socket;
  }

  /// Removes a client. Called by each `Socket`.
  ///
  /// @api private
  void remove(final Socket socket) {
    if (sockets.contains(socket)) {
      sockets.remove(socket);
    } else {
      _logger.fine('ignoring remove for ${socket.id}');
    }
  }

  /// Emits to all clients.
  ///
  /// @api public
  @override
  void emit(final String event, [final dynamic argument]) {
    if (EventName.isReserved(event)) {
      super.emit(event, argument);
    } else {
      // ignore: omit_local_variable_types
      final List<dynamic> data = argument == null ? <dynamic>[event] : <dynamic>[event, argument];

      final Map<String, Object> packet = <String, Object>{'type': EVENT, 'data': data};

      adapter.broadcast(packet, <String, dynamic>{'rooms': rooms, 'flags': flags});

      rooms = <String>[];
      flags = <String, bool>{};
    }
  }

  /// Sends a `message` event to all clients.
  ///
  /// @return {Namespace} self
  /// @api public
  Namespace send([final Object? args]) => write(args);

  Namespace write([final Object? args]) {
    emit('message', args);
    return this;
  }

  /// Gets a list of clients.
  ///
  /// @return {Namespace} self
  /// @api public
  Namespace clients(final List<String>? rooms, [final Function? fn]) {
    adapter.clients(rooms ?? this.rooms, fn as void Function(List<String> p1)?);
    this.rooms = <String>[];
    return this;
  }

  /// Sets the compress flag.
  ///
  /// @param {Boolean} if `true`, compresses the sending data
  /// @return {Namespace} self
  /// @api public
  Namespace compress(final bool compress) {
    flags = flags.isEmpty ? flags : <String, bool>{};
    flags['compress'] = compress;
    return this;
  }

  /// Special method for connection events that pass Socket objects
  /// This provides proper typing for connection handlers
  void onConnection(final EventHandler<Socket> handler) {
    on('connection', (final dynamic data) => handler(data as Socket));
  }
}

/// Apply flags from `Socket`.
