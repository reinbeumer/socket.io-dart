/*
socket.dart

Purpose:

Description:

History:
   22/02/2017, Created by jumperchen

Copyright (C) 2017 Potix Corporation. All Rights Reserved.
*/
import 'dart:io';

import 'package:socket_io_common/socket_io_common.dart';

import 'adapter.dart';
import 'client.dart';
import 'engine/socket.dart' as engine;
import 'models/callbacks_models.dart';
import 'models/handshake_data_models.dart';
import 'models/packet_data_models.dart';
import 'models/packet_models.dart';
import 'models/room_management_models.dart';
import 'models/socket_data_models.dart';
import 'namespace.dart';
import 'server.dart';
import 'util/event_emitter.dart';
import 'value_objects/connection_id_vo.dart';
import 'value_objects/event_name_vo.dart';
import 'value_objects/query_parameters_vo.dart';

/// Represents an individual client connection to the Socket.IO server.
///
/// A [Socket] is the fundamental class for interacting with a client. It allows
/// you to send and receive events, manage rooms, and handle disconnections.
///
/// ## Basic Usage
///
/// ```dart
/// io.on('connection', (socket) {
///   print('Client connected: ${socket.id}');
///
///   // Listen for events
///   socket.on('message', (data) {
///     print('Received: $data');
///   });
///
///   // Emit events
///   socket.emit('welcome', ['Hello, client!']);
///
///   // Handle disconnection
///   socket.on('disconnect', (reason) {
///     print('Client disconnected: $reason');
///   });
/// });
/// ```
///
/// ## Rooms
///
/// ```dart
/// // Join a room
/// socket.join('room1');
///
/// // Emit to all clients in a room
/// io.to('room1').emit('message', ['Room broadcast']);
///
/// // Emit to all except sender
/// socket.broadcast.to('room1').emit('message', ['Others in room']);
///
/// // Leave a room
/// socket.leave('room1');
/// ```
///
/// ## Acknowledgments
///
/// ```dart
/// // Server requests acknowledgment
/// socket.emit('question', ['What is 2+2?'], ack: (response) {
///   print('Client answered: $response');
/// });
///
/// // Server sends acknowledgment
/// socket.on('question', (data) {
///   // Process question
///   return ['The answer is 42'];  // Sent as acknowledgment
/// });
/// ```
///
/// ## Binary Data
///
/// ```dart
/// // Send binary data
/// final bytes = Uint8List.fromList([1, 2, 3, 4]);
/// socket.emit('binary', [bytes]);
///
/// // Receive binary data
/// socket.on('binary', (data) {
///   if (data is List<int>) {
///     print('Received ${data.length} bytes');
///   }
/// });
/// ```
///
/// ## Per-Socket Data
///
/// ```dart
/// // Using typed API
/// socket.socketData.set('userId', 123);
/// final userId = socket.socketData.getInt('userId');
///
/// // Using legacy API
/// socket.data['userId'] = 123;
/// final userId = socket.data['userId'];
/// ```
///
/// See also:
/// * [Namespace] for namespace-level operations
/// * [Server.on] for handling connection events
class Socket extends EventEmitter {
  // ignore: undefined_class
  Namespace nsp;
  Client client;
  late Server server;
  late Adapter adapter;
  late ConnectionId connectionId;
  late String id; // Keep for backward compatibility
  late HttpRequest request;
  late engine.Socket conn;

  // New typed room management
  RoomMembership roomMembership = RoomMembership();
  // Keep for backward compatibility
  Map<String, dynamic> roomMap = <String, dynamic>{};

  List<String> roomList = <String>[];
  Map<String, AckCallback> acksTyped = <String, AckCallback>{}; // New typed version
  Map<String, Function> acks = <String, Function>{}; // Keep for backward compatibility
  bool connected = true;
  bool disconnected = false;
  HandshakeDataModel? handshakeData; // New typed version
  Map<String, dynamic>? handshake; // Keep for backward compatibility
  Map<String, bool>? flags;

  // a data store for each socket - new typed version
  SocketDataModel socketData = SocketDataModel();
  // Keep old version for backward compatibility
  Map<String, dynamic> data = <String, dynamic>{};

  // New typed query parameters
  QueryParameters? queryParameters;

  Socket(this.nsp, this.client, final Map<String, dynamic>? query) {
    server = nsp.server;
    adapter = nsp.adapter;
    id = client.id;
    connectionId = ConnectionId(client.id);
    request = client.request;
    conn = client.conn;

    // Convert query to QueryParameters if provided
    if (query != null && query.isNotEmpty) {
      queryParameters = QueryParameters(query);
    }

    handshake = buildHandshake(query);
    handshakeData = buildHandshakeTyped(query);
    // Sync data between old and new storage
    data = socketData.toMap();
  }

  /// Typed constructor using QueryParameters
  Socket.typed(this.nsp, this.client, this.queryParameters) {
    server = nsp.server;
    adapter = nsp.adapter;
    id = client.id;
    connectionId = ConnectionId(client.id);
    request = client.request;
    conn = client.conn;

    // Convert QueryParameters to Map for backward compatibility
    final Map<String, dynamic>? query = queryParameters?.toDynamicMap();

    handshake = buildHandshake(query);
    handshakeData = buildHandshakeTyped(query);
    // Sync data between old and new storage
    data = socketData.toMap();
  }

  /// Checks if the current connection is secure (HTTPS/WSS).
  ///
  /// Determines security based on:
  /// - URI scheme (https/wss)
  /// - X-Forwarded-Proto header (for proxied connections)
  ///
  /// @return {bool} true if connection is secure
  /// @api private
  bool _isSecureConnection() {
    // Check if request URI scheme is secure
    final String scheme = request.uri.scheme.toLowerCase();
    if (scheme == 'https' || scheme == 'wss') {
      return true;
    }

    // Check X-Forwarded-Proto header for proxied HTTPS connections
    final String? forwardedProto = request.headers.value('x-forwarded-proto');
    if (forwardedProto?.toLowerCase() == 'https') {
      return true;
    }

    // Check connection info if available (some platforms may not support this)
    try {
      final HttpConnectionInfo? connectionInfo = request.connectionInfo;
      if (connectionInfo != null) {
        // For HTTP/2 or when the connection is encrypted
        return connectionInfo.remotePort == 443;
      }
    } catch (e) {
      // connectionInfo may not be available on all platforms
    }

    return false;
  }

  /// Detects if data contains binary content.
  ///
  /// Binary data is detected by checking if:
  /// - Data is a List<int> (byte array)
  /// - Data is a List containing any List<int> elements
  ///
  /// @param {dynamic} data - The data to check
  /// @return {bool} true if data contains binary content
  /// @api private
  bool _containsBinaryData(final dynamic data) {
    if (data == null) return false;

    // Check if data itself is binary (List<int>)
    if (data is List<int>) return true;

    // Check if data is a List containing binary data
    if (data is List) {
      for (final dynamic item in data) {
        if (item is List<int>) return true;
        // Recursively check nested lists
        if (item is List && _containsBinaryData(item)) return true;
      }
    }

    // Check if data is a Map containing binary values
    if (data is Map) {
      for (final dynamic value in data.values) {
        if (_containsBinaryData(value)) return true;
      }
    }

    return false;
  }

  /// Builds the `handshake` BC object (legacy version)
  ///
  /// @api private
  Map<String, dynamic> buildHandshake(final Map<String, dynamic>? query) {
    Map<String, dynamic> buildQuery() {
      final Map<String, String> requestQuery = request.uri.queryParameters;
      //if socket-specific query exist, replace query strings in requestQuery
      return query != null ? (Map<String, dynamic>.from(query)..addAll(requestQuery)) : requestQuery;
    }

    return <String, dynamic>{
      'headers': request.headers,
      'time': DateTime.now().toString(),
      'address': conn.remoteAddress,
      'xdomain': request.headers.value('origin') != null,
      'secure': _isSecureConnection(),
      'issued': DateTime.now().millisecondsSinceEpoch,
      'url': request.uri.path,
      'query': buildQuery()
    };
  }

  /// Builds the typed `handshake` object (new version)
  ///
  /// @api private
  HandshakeDataModel buildHandshakeTyped(final Map<String, dynamic>? query) {
    Map<String, String> buildQuery() {
      final Map<String, String> requestQuery = request.uri.queryParameters;
      //if socket-specific query exist, replace query strings in requestQuery
      if (query != null) {
        final Map<String, String> combined = Map<String, String>.from(requestQuery);
        query.forEach((final String key, final dynamic value) {
          combined[key] = value.toString();
        });
        return combined;
      }
      return requestQuery;
    }

    return HandshakeDataBuilder()
        .headers(request.headers)
        .time(DateTime.now())
        .address(conn.remoteAddress)
        .xdomain(request.headers.value('origin') != null)
        .secure(_isSecureConnection())
        .issued(DateTime.now().millisecondsSinceEpoch)
        .url(request.uri.path)
        .queryMap(buildQuery())
        .build();
  }

  Socket get json {
    flags = flags ?? <String, bool>{};
    flags!['json'] = true;
    return this;
  }

  Socket get volatile {
    flags = flags ?? <String, bool>{};
    flags!['volatile'] = true;
    return this;
  }

  Socket get broadcast {
    flags = flags ?? <String, bool>{};
    flags!['broadcast'] = true;
    return this;
  }

  @override
  void emit(final String event, [final dynamic data]) {
    emitWithAck(event, data);
  }

  void emitWithBinary(final String event, [final dynamic data]) {
    emitWithAck(event, data, binary: true);
  }

  /// Emits to this client.
  ///
  /// @return {Socket} self
  /// @api public
  void emitWithAck(final String event, final dynamic data, {final Function? ack, final bool binary = false}) {
    if (EventName.isReserved(event)) {
      super.emit(event, data);
    } else {
      final List<dynamic> sendData = data == null ? <dynamic>[event] : <dynamic>[event, data];
      final Map<String, bool> flags = this.flags ?? <String, bool>{};

      String? packetId;
      if (ack != null) {
        if (roomList.isNotEmpty || flags['broadcast'] == true) {
          throw UnsupportedError('Callbacks are not supported when broadcasting');
        }

        packetId = '${nsp.ids++}';
        acks[packetId] = ack;
      }

      // Create typed packet instead of dynamic map
      final EventPacket eventPacket = EventPacket.typed(
        typedData: EventPacketData.fromList(sendData),
        namespace: nsp.name,
        id: packetId,
        binary: binary,
      );

      if (roomList.isNotEmpty || flags['broadcast'] == true) {
        adapter.broadcast(eventPacket.toMap(), <String, dynamic>{
          'except': <String>[id],
          'rooms': roomList,
          'flags': flags
        });
      } else {
        // dispatch packet with proper options typing
        sendPacket(
            eventPacket,
            PacketOptions(
              volatile: flags['volatile'] ?? false,
              compress: flags['compress'] ?? false,
            ));
      }

      // reset flags
      roomList = <String>[];
      this.flags = null;
    }
  }

  /// Targets a room when broadcasting.
  ///
  /// @param {String} name
  /// @return {Socket} self
  /// @api public
  Socket to(final String name) {
    if (!roomList.contains(name)) roomList.add(name);
    return this;
  }

  /// Sends a `message` event.
  ///
  /// @return {Socket} self
  /// @api public
  void send(final dynamic data) {
    write(data as List<dynamic>);
  }

  Socket write(final List<dynamic> data) {
    emit('message', data);
    return this;
  }

  /// Writes a packet using typed models.
  ///
  /// @param {SocketIOPacket} packet typed packet object
  /// @param {PacketOptions} options packet options
  /// @api private
  void sendPacket(final SocketIOPacket packet, final PacketOptions options) {
    final Map<String, dynamic> packetMap = packet.toMap();
    // Set namespace if not already set
    if (packetMap['nsp'] == null) {
      packetMap['nsp'] = nsp.name;
    }
    client.packet(packetMap, options.toMap());
  }

  /// Writes a packet (legacy method for backward compatibility).
  ///
  /// @param {Object} packet object
  /// @param {Object} options
  /// @api private
  void packet(final Map<String, dynamic> packet, [final Map<String, Object>? opts]) {
    // ignore preEncoded = true.
    packet['nsp'] = nsp.name;
    final Map<String, Object> options = opts ?? <String, Object>{};
    options['compress'] = options['compress'] != false;
    client.packet(packet, options);
  }

  /// Joins a room.
  ///
  /// @param {String} room
  /// @param {Function} optional, callback
  /// @return {Socket} self
  /// @api private
  Socket join(final String room, [final Function? fn]) {
    if (roomMembership.containsName(room)) {
      if (fn != null) fn(null);
      return this;
    }
    adapter.add(id, room, ([final Object? err]) {
      if (err != null) {
        fn?.call(err);
        return;
      }
      // Update new typed model
      roomMembership.addByName(room);
      // Keep old map in sync for backward compatibility
      roomMap[room] = room;
      if (fn != null) fn(null);
    });
    return this;
  }

  /// Leaves a room.
  ///
  /// @param {String} room
  /// @param {Function} optional, callback
  /// @return {Socket} self
  /// @api private
  Socket leave(final String room, final Function? fn) {
    adapter.del(id, room, ([final Object? err]) {
      if (err != null) {
        fn?.call(err);
        return;
      }
      // Update new typed model
      roomMembership.removeByName(room);
      // Keep old map in sync for backward compatibility
      roomMap.remove(room);
      fn?.call(null);
    });
    return this;
  }

  /// Leave all rooms.
  ///
  /// @api private

  void leaveAll() {
    adapter.delAll(id);
    // Clear new typed model
    roomMembership.clear();
    // Keep old map in sync for backward compatibility
    roomMap = <String, dynamic>{};
  }

  /// Called by `Namespace` upon succesful
  /// middleware execution (ie: authorization).
  ///
  /// @api private

  void onconnect() {
    nsp.connected[id] = this;
    join(id);
    // Socket.IO v3: Include socket ID in CONNECT packet using typed model
    final ConnectPacket connectPacket = ConnectPacket.typed(
      namespace: nsp.name,
      typedData: ConnectPacketData(sid: id),
    );
    sendPacket(connectPacket, PacketOptions());
  }

  /// Called with each packet. Called by `Client`.
  ///
  /// @param {Object} packet
  /// @api private
  void onpacket(final Map<String, dynamic> packet) {
    switch (packet['type']) {
      case EVENT:
        onevent(packet);
        break;

      case BINARY_EVENT:
        onevent(packet);
        break;

      case ACK:
        onack(packet);
        break;

      case BINARY_ACK:
        onack(packet);
        break;

      case DISCONNECT:
        ondisconnect();
        break;

      case CONNECT_ERROR:
        emit('error', packet['data']);
    }
  }

  /// Called upon event packet.
  ///
  /// @param {Object} packet object
  /// @api private
  void onevent(final Map<String, dynamic> packet) {
    final List<dynamic> args = (packet['data'] as List<dynamic>?) ?? <dynamic>[];

    if (null != packet['id']) {
      args.add(ack(packet['id']));
    }

    // dart doesn't support "String... rest" syntax.
    if (args.length > 2) {
      Function.apply(super.emit, <dynamic>[args.first, args.sublist(1)]);
    } else {
      Function.apply(super.emit, args);
    }
  }

  /// Produces an ack callback to emit with an event.
  ///
  /// @param {Number} packet id
  /// @api private
  AckFunction ack(final String id) {
    bool sent = false;
    return (final dynamic data) {
      // prevent double callbacks
      if (sent) return;
//      var args = Array.prototype.slice.call(arguments);

      // Use typed AckPacket instead of dynamic map
      final AckPacket ackPacket = AckPacket.typed(
        id: id.toString(),
        typedData: AckPacketData.fromList(<dynamic>[data]),
        namespace: nsp.name,
        binary: _containsBinaryData(data),
      );
      sendPacket(ackPacket, PacketOptions());
      sent = true;
    };
  }

  /// Called upon ack packet.
  ///
  /// @api private
  void onack(final Map<String, dynamic> packet) {
    final Function ack = acks.remove(packet['id']) as Function;
    Function.apply(ack, packet['data'] as List<dynamic>?);
  }

  /// Called upon client disconnect packet.
  ///
  /// @api private
  void ondisconnect() {
    onclose('client namespace disconnect');
  }

  /// Handles a client error.
  ///
  /// @api private
  void onerror(final Object err) {
    if (hasListeners('error')) {
      emit('error', err);
    } else {
//      console.error('Missing error handler on `socket`.');
//      console.error(err.stack);
    }
  }

  /// Called upon closing. Called by `Client`.
  ///
  /// @param {String} reason
  /// @param {Error} optional error object
  /// @api private
  void onclose([final String? reason]) {
    if (!connected) return;
    emit('disconnecting', reason);
    leaveAll();
    nsp.remove(this);
    client.remove(this);
    connected = false;
    disconnected = true;
    nsp.connected.remove(id);
    emit('disconnect', reason);
  }

  /// Produces an `error` packet.
  ///
  /// @param {Object} error object
  /// @api private
  void error(final Object err) {
    final ConnectErrorPacket errorPacket = ConnectErrorPacket.typed(
      typedData: ConnectErrorPacketData.fromJson(err),
      namespace: nsp.name,
    );
    sendPacket(errorPacket, PacketOptions());
  }

  /// Disconnects this client.
  ///
  /// @param {Boolean} if `true`, closes the underlying connection
  /// @return {Socket} self
  /// @api public
  Socket disconnect([final bool? close]) {
    if (!connected) return this;
    if (close == true) {
      client.disconnect();
    } else {
      final DisconnectPacket disconnectPacket = DisconnectPacket.typed(
        namespace: nsp.name,
      );
      sendPacket(disconnectPacket, PacketOptions());
      onclose('server namespace disconnect');
    }
    return this;
  }

  /// Sets the compress flag.
  ///
  /// @param {Boolean} if `true`, compresses the sending data
  /// @return {Socket} self
  /// @api public
  Socket compress(final dynamic compress) {
    flags = flags ?? <String, bool>{};
    flags!['compress'] = compress as bool;
    return this;
  }
}
