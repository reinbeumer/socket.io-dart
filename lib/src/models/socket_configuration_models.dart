/// socket_configuration_models.dart
///
/// Typed configuration models for Socket.IO socket to replace Map<String, dynamic> handshake,
/// Map<String, bool> flags, and other socket-related dynamic types with proper model classes.
library socket_configuration_models;

import 'package:meta/meta.dart';
import 'client_configuration_models.dart';

/// Configuration model for socket handshake data.
/// Replaces Map<String, dynamic> handshake throughout the codebase.
@immutable
class HandshakeModel {
  /// The socket ID assigned during handshake.
  final String id;

  /// Headers sent during the handshake.
  final Map<String, String> headers;

  /// Query parameters from the handshake.
  final QueryParametersModel query;

  /// Authentication data if provided.
  final Map<String, Object?> auth;

  /// Client address information.
  final String address;

  /// Whether the connection is secure (HTTPS/WSS).
  final bool secure;

  /// The time when the handshake was performed.
  final DateTime handshakeTime;

  /// User agent information.
  final String? userAgent;

  /// Referer information.
  final String? referer;

  /// Origin of the request.
  final String? origin;

  /// Additional custom data from the handshake.
  final Map<String, Object?> customData;

  /// Creates a new handshake model.
  const HandshakeModel({
    required this.id,
    this.headers = const <String, String>{},
    this.query = const QueryParametersModel.empty(),
    this.auth = const <String, Object?>{},
    required this.address,
    this.secure = false,
    required this.handshakeTime,
    this.userAgent,
    this.referer,
    this.origin,
    this.customData = const <String, Object?>{},
  });

  /// Creates a handshake model from legacy Map<String, dynamic>.
  factory HandshakeModel.fromMap(final Map<String, dynamic> map) => HandshakeModel(
        id: map['id'] as String? ?? '',
        headers: _parseHeaders(map['headers']),
        query: QueryParametersModel.fromMap(map['query'] as Map<String, String>?),
        auth: map['auth'] as Map<String, Object?>? ?? <String, Object?>{},
        address: map['address'] as String? ?? '',
        secure: map['secure'] as bool? ?? false,
        handshakeTime: _parseDateTime(map['time']) ?? DateTime.now(),
        userAgent: map['userAgent'] as String?,
        referer: map['referer'] as String?,
        origin: map['origin'] as String?,
        customData: _extractCustomData(map),
      );

  /// Creates a handshake model from an HTTP request context.
  factory HandshakeModel.fromRequest({
    required final String id,
    required final String address,
    final Map<String, String> headers = const <String, String>{},
    final QueryParametersModel query = const QueryParametersModel.empty(),
    final Map<String, Object?> auth = const <String, Object?>{},
    final bool secure = false,
  }) =>
      HandshakeModel(
        id: id,
        headers: headers,
        query: query,
        auth: auth,
        address: address,
        secure: secure,
        handshakeTime: DateTime.now(),
        userAgent: headers['user-agent'],
        referer: headers['referer'],
        origin: headers['origin'],
      );

  /// Gets a header value by name (case-insensitive).
  String? getHeader(final String name) {
    final String lowerName = name.toLowerCase();
    for (final MapEntry<String, String> entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }
    return null;
  }

  /// Gets authentication data by key.
  T? getAuth<T>(final String key) => auth[key] as T?;

  /// Checks if authentication data exists.
  bool hasAuth(final String key) => auth.containsKey(key);

  /// Gets custom data by key.
  T? getCustomData<T>(final String key) => customData[key] as T?;

  /// Checks if custom data exists.
  bool hasCustomData(final String key) => customData.containsKey(key);

  /// Converts to a legacy Map<String, dynamic> for backward compatibility.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'id': id,
      'headers': headers,
      'query': query.toMap(),
      'auth': auth,
      'address': address,
      'secure': secure,
      'time': handshakeTime.millisecondsSinceEpoch,
    };

    if (userAgent != null) map['userAgent'] = userAgent;
    if (referer != null) map['referer'] = referer;
    if (origin != null) map['origin'] = origin;

    // Add custom data to the map
    map.addAll(customData);

    return map;
  }

  /// Creates a copy with optional parameter overrides.
  HandshakeModel copyWith({
    final String? id,
    final Map<String, String>? headers,
    final QueryParametersModel? query,
    final Map<String, Object?>? auth,
    final String? address,
    final bool? secure,
    final DateTime? handshakeTime,
    final String? userAgent,
    final String? referer,
    final String? origin,
    final Map<String, Object?>? customData,
  }) =>
      HandshakeModel(
        id: id ?? this.id,
        headers: headers ?? this.headers,
        query: query ?? this.query,
        auth: auth ?? this.auth,
        address: address ?? this.address,
        secure: secure ?? this.secure,
        handshakeTime: handshakeTime ?? this.handshakeTime,
        userAgent: userAgent ?? this.userAgent,
        referer: referer ?? this.referer,
        origin: origin ?? this.origin,
        customData: customData ?? this.customData,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HandshakeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          _mapsEqual(headers, other.headers) &&
          query == other.query &&
          _mapsEqual(auth, other.auth) &&
          address == other.address &&
          secure == other.secure &&
          handshakeTime == other.handshakeTime &&
          userAgent == other.userAgent &&
          referer == other.referer &&
          origin == other.origin &&
          _mapsEqual(customData, other.customData);

  @override
  int get hashCode =>
      id.hashCode ^
      headers.hashCode ^
      query.hashCode ^
      auth.hashCode ^
      address.hashCode ^
      secure.hashCode ^
      handshakeTime.hashCode ^
      userAgent.hashCode ^
      referer.hashCode ^
      origin.hashCode ^
      customData.hashCode;

  @override
  String toString() => 'HandshakeModel('
      'id: $id, '
      'address: $address, '
      'secure: $secure, '
      'handshakeTime: $handshakeTime, '
      'headers: ${headers.length}, '
      'query: $query, '
      'auth: ${auth.length}, '
      'customData: ${customData.length})';

  // Helper methods
  static Map<String, String> _parseHeaders(final dynamic headers) {
    if (headers is Map<String, String>) return headers;
    if (headers is Map) {
      return headers.map((final dynamic k, final dynamic v) => MapEntry<String, String>(k.toString(), v.toString()));
    }
    return <String, String>{};
  }

  static DateTime? _parseDateTime(final dynamic time) {
    if (time is DateTime) return time;
    if (time is int) return DateTime.fromMillisecondsSinceEpoch(time);
    if (time is String) return DateTime.tryParse(time);
    return null;
  }

  static Map<String, Object?> _extractCustomData(final Map<String, dynamic> map) {
    final Map<String, Object?> customData = <String, Object?>{};
    final Set<String> knownKeys = <String>{
      'id',
      'headers',
      'query',
      'auth',
      'address',
      'secure',
      'time',
      'userAgent',
      'referer',
      'origin'
    };

    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (!knownKeys.contains(entry.key)) {
        customData[entry.key] = entry.value;
      }
    }

    return customData;
  }

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, Object?> a, final Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Object?> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model for socket flags.
/// Replaces Map<String, bool> flags with proper typed structure.
@immutable
class SocketFlagsModel {
  /// Whether the message is volatile (not persisted if client is offline).
  final bool volatile;

  /// Whether to compress the message.
  final bool compress;

  /// Whether to broadcast to all clients.
  final bool broadcast;

  /// Whether to include the sender.
  final bool includeSender;

  /// Whether this is a binary message.
  final bool binary;

  /// Whether to acknowledge receipt.
  final bool ack;

  /// Custom flags for extensibility.
  final Map<String, bool> customFlags;

  /// Creates a new socket flags model.
  const SocketFlagsModel({
    this.volatile = false,
    this.compress = false,
    this.broadcast = false,
    this.includeSender = true,
    this.binary = false,
    this.ack = false,
    this.customFlags = const <String, bool>{},
  });

  /// Creates socket flags from legacy Map<String, bool>.
  factory SocketFlagsModel.fromMap(final Map<String, bool>? map) {
    if (map == null || map.isEmpty) {
      return const SocketFlagsModel();
    }

    return SocketFlagsModel(
      volatile: map['volatile'] ?? false,
      compress: map['compress'] ?? false,
      broadcast: map['broadcast'] ?? false,
      includeSender: map['includeSender'] ?? true,
      binary: map['binary'] ?? false,
      ack: map['ack'] ?? false,
      customFlags: _extractCustomFlags(map),
    );
  }

  /// Creates volatile socket flags.
  const SocketFlagsModel.volatile() : this(volatile: true);

  /// Creates compress socket flags.
  const SocketFlagsModel.compress() : this(compress: true);

  /// Creates broadcast socket flags.
  const SocketFlagsModel.broadcast() : this(broadcast: true);

  /// Creates binary socket flags.
  const SocketFlagsModel.binary() : this(binary: true);

  /// Creates acknowledgment socket flags.
  const SocketFlagsModel.ack() : this(ack: true);

  /// Gets a flag value by name.
  bool getFlag(final String name) {
    switch (name) {
      case 'volatile':
        return volatile;
      case 'compress':
        return compress;
      case 'broadcast':
        return broadcast;
      case 'includeSender':
        return includeSender;
      case 'binary':
        return binary;
      case 'ack':
        return ack;
      default:
        return customFlags[name] ?? false;
    }
  }

  /// Checks if any flags are set.
  bool get hasAnyFlag => volatile || compress || broadcast || !includeSender || binary || ack || customFlags.isNotEmpty;

  /// Gets all active flags as a list.
  List<String> get activeFlags {
    final List<String> flags = <String>[];
    if (volatile) flags.add('volatile');
    if (compress) flags.add('compress');
    if (broadcast) flags.add('broadcast');
    if (!includeSender) flags.add('excludeSender');
    if (binary) flags.add('binary');
    if (ack) flags.add('ack');

    for (final MapEntry<String, bool> entry in customFlags.entries) {
      if (entry.value) flags.add(entry.key);
    }

    return flags;
  }

  /// Converts to legacy Map<String, bool> for backward compatibility.
  Map<String, bool> toMap() {
    final Map<String, bool> map = <String, bool>{
      'volatile': volatile,
      'compress': compress,
      'broadcast': broadcast,
      'includeSender': includeSender,
      'binary': binary,
      'ack': ack,
    }..addAll(customFlags);

    return map;
  }

  /// Creates a copy with optional parameter overrides.
  SocketFlagsModel copyWith({
    final bool? volatile,
    final bool? compress,
    final bool? broadcast,
    final bool? includeSender,
    final bool? binary,
    final bool? ack,
    final Map<String, bool>? customFlags,
  }) =>
      SocketFlagsModel(
        volatile: volatile ?? this.volatile,
        compress: compress ?? this.compress,
        broadcast: broadcast ?? this.broadcast,
        includeSender: includeSender ?? this.includeSender,
        binary: binary ?? this.binary,
        ack: ack ?? this.ack,
        customFlags: customFlags ?? this.customFlags,
      );

  /// Combines this flags model with another.
  SocketFlagsModel combine(final SocketFlagsModel other) {
    final Map<String, bool> combinedCustomFlags = Map<String, bool>.from(customFlags)..addAll(other.customFlags);

    return SocketFlagsModel(
      volatile: volatile || other.volatile,
      compress: compress || other.compress,
      broadcast: broadcast || other.broadcast,
      includeSender: includeSender && other.includeSender,
      binary: binary || other.binary,
      ack: ack || other.ack,
      customFlags: combinedCustomFlags,
    );
  }

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SocketFlagsModel &&
          runtimeType == other.runtimeType &&
          volatile == other.volatile &&
          compress == other.compress &&
          broadcast == other.broadcast &&
          includeSender == other.includeSender &&
          binary == other.binary &&
          ack == other.ack &&
          _mapsEqual(customFlags, other.customFlags);

  @override
  int get hashCode =>
      volatile.hashCode ^
      compress.hashCode ^
      broadcast.hashCode ^
      includeSender.hashCode ^
      binary.hashCode ^
      ack.hashCode ^
      customFlags.hashCode;

  @override
  String toString() => 'SocketFlagsModel('
      'volatile: $volatile, '
      'compress: $compress, '
      'broadcast: $broadcast, '
      'includeSender: $includeSender, '
      'binary: $binary, '
      'ack: $ack, '
      'customFlags: $customFlags)';

  // Helper methods
  static Map<String, bool> _extractCustomFlags(final Map<String, bool> map) {
    final Map<String, bool> customFlags = <String, bool>{};
    final Set<String> knownFlags = <String>{'volatile', 'compress', 'broadcast', 'includeSender', 'binary', 'ack'};

    for (final MapEntry<String, bool> entry in map.entries) {
      if (!knownFlags.contains(entry.key)) {
        customFlags[entry.key] = entry.value;
      }
    }

    return customFlags;
  }

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, bool> a, final Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, bool> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Configuration model for room management.
/// Replaces roomMap and roomList management with proper typed structure.
@immutable
class RoomManagementModel {
  /// Map of room names to socket IDs.
  final Map<String, Set<String>> rooms;

  /// Map of socket IDs to room names they belong to.
  final Map<String, Set<String>> socketRooms;

  /// Maximum number of rooms a socket can join.
  final int maxRoomsPerSocket;

  /// Maximum number of sockets per room.
  final int maxSocketsPerRoom;

  /// Creates a new room management model.
  const RoomManagementModel({
    this.rooms = const <String, Set<String>>{},
    this.socketRooms = const <String, Set<String>>{},
    this.maxRoomsPerSocket = 100,
    this.maxSocketsPerRoom = 10000,
  });

  /// Creates an empty room management model.
  const RoomManagementModel.empty() : this();

  /// Adds a socket to a room.
  RoomManagementModel addSocketToRoom(final String socketId, final String roomName) {
    // Check limits
    final Set<String> currentRooms = socketRooms[socketId] ?? <String>{};
    if (currentRooms.length >= maxRoomsPerSocket) {
      return this; // Limit reached
    }

    final Set<String> currentSockets = rooms[roomName] ?? <String>{};
    if (currentSockets.length >= maxSocketsPerRoom) {
      return this; // Limit reached
    }

    // Create new maps
    final Map<String, Set<String>> newRooms = Map<String, Set<String>>.from(rooms);
    final Map<String, Set<String>> newSocketRooms = Map<String, Set<String>>.from(socketRooms);

    // Add socket to room
    final Set<String> roomSockets = Set<String>.from(currentSockets)..add(socketId);
    newRooms[roomName] = roomSockets;

    // Add room to socket
    final Set<String> socketRoomSet = Set<String>.from(currentRooms)..add(roomName);
    newSocketRooms[socketId] = socketRoomSet;

    return copyWith(rooms: newRooms, socketRooms: newSocketRooms);
  }

  /// Removes a socket from a room.
  RoomManagementModel removeSocketFromRoom(final String socketId, final String roomName) {
    final Map<String, Set<String>> newRooms = Map<String, Set<String>>.from(rooms);
    final Map<String, Set<String>> newSocketRooms = Map<String, Set<String>>.from(socketRooms);

    // Remove socket from room
    if (newRooms.containsKey(roomName)) {
      final Set<String> roomSockets = Set<String>.from(newRooms[roomName]!)..remove(socketId);
      if (roomSockets.isEmpty) {
        newRooms.remove(roomName);
      } else {
        newRooms[roomName] = roomSockets;
      }
    }

    // Remove room from socket
    if (newSocketRooms.containsKey(socketId)) {
      final Set<String> socketRoomSet = Set<String>.from(newSocketRooms[socketId]!)..remove(roomName);
      if (socketRoomSet.isEmpty) {
        newSocketRooms.remove(socketId);
      } else {
        newSocketRooms[socketId] = socketRoomSet;
      }
    }

    return copyWith(rooms: newRooms, socketRooms: newSocketRooms);
  }

  /// Removes a socket from all rooms.
  RoomManagementModel removeSocket(final String socketId) {
    final Set<String> socketRoomSet = socketRooms[socketId] ?? <String>{};
    if (socketRoomSet.isEmpty) return this;

    RoomManagementModel result = this;
    for (final String roomName in socketRoomSet) {
      result = result.removeSocketFromRoom(socketId, roomName);
    }
    return result;
  }

  /// Gets all sockets in a room.
  Set<String> getSocketsInRoom(final String roomName) => Set<String>.from(rooms[roomName] ?? <String>{});

  /// Gets all rooms a socket belongs to.
  Set<String> getSocketRooms(final String socketId) => Set<String>.from(socketRooms[socketId] ?? <String>{});

  /// Checks if a socket is in a room.
  bool isSocketInRoom(final String socketId, final String roomName) => rooms[roomName]?.contains(socketId) ?? false;

  /// Gets all room names.
  Set<String> get allRooms => rooms.keys.toSet();

  /// Gets all socket IDs.
  Set<String> get allSockets => socketRooms.keys.toSet();

  /// Gets the total number of rooms.
  int get roomCount => rooms.length;

  /// Gets the total number of sockets.
  int get socketCount => socketRooms.length;

  /// Checks if the model is empty.
  bool get isEmpty => rooms.isEmpty && socketRooms.isEmpty;

  /// Converts to legacy format for backward compatibility.
  Map<String, dynamic> toLegacyFormat() => <String, dynamic>{
        'rooms': rooms.map(
            (final String room, final Set<String> sockets) => MapEntry<String, List<String>>(room, sockets.toList())),
        'socketRooms': socketRooms.map(
            (final String socket, final Set<String> rooms) => MapEntry<String, List<String>>(socket, rooms.toList())),
      };

  /// Creates a copy with optional parameter overrides.
  RoomManagementModel copyWith({
    final Map<String, Set<String>>? rooms,
    final Map<String, Set<String>>? socketRooms,
    final int? maxRoomsPerSocket,
    final int? maxSocketsPerRoom,
  }) =>
      RoomManagementModel(
        rooms: rooms ?? this.rooms,
        socketRooms: socketRooms ?? this.socketRooms,
        maxRoomsPerSocket: maxRoomsPerSocket ?? this.maxRoomsPerSocket,
        maxSocketsPerRoom: maxSocketsPerRoom ?? this.maxSocketsPerRoom,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RoomManagementModel &&
          runtimeType == other.runtimeType &&
          _mapSetsEqual(rooms, other.rooms) &&
          _mapSetsEqual(socketRooms, other.socketRooms) &&
          maxRoomsPerSocket == other.maxRoomsPerSocket &&
          maxSocketsPerRoom == other.maxSocketsPerRoom;

  @override
  int get hashCode => rooms.hashCode ^ socketRooms.hashCode ^ maxRoomsPerSocket.hashCode ^ maxSocketsPerRoom.hashCode;

  @override
  String toString() => 'RoomManagementModel('
      'roomCount: $roomCount, '
      'socketCount: $socketCount, '
      'maxRoomsPerSocket: $maxRoomsPerSocket, '
      'maxSocketsPerRoom: $maxSocketsPerRoom)';

  /// Helper method to compare map of sets for equality.
  bool _mapSetsEqual(final Map<String, Set<String>> a, final Map<String, Set<String>> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, Set<String>> entry in a.entries) {
      final Set<String>? bSet = b[entry.key];
      if (bSet == null || entry.value.length != bSet.length) return false;
      for (final String item in entry.value) {
        if (!bSet.contains(item)) return false;
      }
    }
    return true;
  }
}

/// Query builder model to replace nested buildQuery() functions.
/// Provides a clean, testable way to build query strings.
@immutable
class QueryBuilderModel {
  /// Base query parameters.
  final QueryParametersModel baseQuery;

  /// Additional dynamic parameters.
  final Map<String, String> dynamicParams;

  /// Whether to URL encode parameters.
  final bool urlEncode;

  /// Creates a new query builder model.
  const QueryBuilderModel({
    this.baseQuery = const QueryParametersModel.empty(),
    this.dynamicParams = const <String, String>{},
    this.urlEncode = true,
  });

  /// Creates a query builder from legacy parameters.
  factory QueryBuilderModel.fromLegacyParams(final Map<String, String>? params) => QueryBuilderModel(
        baseQuery: QueryParametersModel.fromMap(params),
      );

  /// Adds a parameter to the builder.
  QueryBuilderModel addParameter(final String key, final String value) {
    final Map<String, String> newDynamicParams = Map<String, String>.from(dynamicParams);
    newDynamicParams[key] = value;
    return copyWith(dynamicParams: newDynamicParams);
  }

  /// Adds multiple parameters to the builder.
  QueryBuilderModel addParameters(final Map<String, String> params) {
    final Map<String, String> newDynamicParams = Map<String, String>.from(dynamicParams)..addAll(params);
    return copyWith(dynamicParams: newDynamicParams);
  }

  /// Removes a parameter from the builder.
  QueryBuilderModel removeParameter(final String key) {
    final Map<String, String> newDynamicParams = Map<String, String>.from(dynamicParams)..remove(key);
    return copyWith(dynamicParams: newDynamicParams);
  }

  /// Builds the final query parameters.
  QueryParametersModel build() {
    final Map<String, String> allParams = Map<String, String>.from(baseQuery.parameters)..addAll(dynamicParams);
    return QueryParametersModel(allParams);
  }

  /// Builds a query string.
  String buildQueryString() => build().toQueryString();

  /// Gets all parameters as a merged map.
  Map<String, String> getAllParameters() {
    final Map<String, String> allParams = Map<String, String>.from(baseQuery.parameters)..addAll(dynamicParams);
    return allParams;
  }

  /// Checks if the builder has any parameters.
  bool get hasParameters => baseQuery.isNotEmpty || dynamicParams.isNotEmpty;

  /// Creates a copy with optional parameter overrides.
  QueryBuilderModel copyWith({
    final QueryParametersModel? baseQuery,
    final Map<String, String>? dynamicParams,
    final bool? urlEncode,
  }) =>
      QueryBuilderModel(
        baseQuery: baseQuery ?? this.baseQuery,
        dynamicParams: dynamicParams ?? this.dynamicParams,
        urlEncode: urlEncode ?? this.urlEncode,
      );

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is QueryBuilderModel &&
          runtimeType == other.runtimeType &&
          baseQuery == other.baseQuery &&
          _mapsEqual(dynamicParams, other.dynamicParams) &&
          urlEncode == other.urlEncode;

  @override
  int get hashCode => baseQuery.hashCode ^ dynamicParams.hashCode ^ urlEncode.hashCode;

  @override
  String toString() => 'QueryBuilderModel('
      'baseQuery: $baseQuery, '
      'dynamicParams: $dynamicParams, '
      'urlEncode: $urlEncode)';

  /// Helper method to compare maps for equality.
  bool _mapsEqual(final Map<String, String> a, final Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final MapEntry<String, String> entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
