/// callbacks_models.dart
///
/// Type-safe callback definitions for Socket.IO operations
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library callbacks_models;

import '../value_objects/connection_id_vo.dart';

/// Callback for acknowledgment responses.
///
/// Takes a list of arguments sent back from the other side.
typedef AckCallback = void Function(List<Object?> args);

/// Function that sends an acknowledgment with data.
///
/// This is the return type of Socket.ack() method.
/// Takes dynamic data and sends it as an acknowledgment response.
typedef AckFunction = void Function(dynamic data);

/// Callback for error events.
///
/// Takes an error object (will be typed as SocketError when available).
typedef ErrorCallback = void Function(Object error);

/// Callback for connection events.
///
/// Takes a socket instance (will be typed when Socket class is available).
typedef ConnectionCallback = void Function(Object socket);

/// Callback for disconnect events.
///
/// Takes a disconnect reason string (will be typed as DisconnectReason when available).
typedef DisconnectCallback = void Function(String reason);

/// Middleware callback function.
///
/// Takes a socket and a next function to continue the middleware chain.
typedef MiddlewareCallback = void Function(Object socket, MiddlewareNext next);

/// Next function in middleware chain.
///
/// Takes an optional error to short-circuit the chain.
typedef MiddlewareNext = void Function(Object? error);

/// Callback for clients list queries.
///
/// Takes a list of connection IDs.
typedef ClientsCallback = void Function(List<ConnectionId> clients);

/// Callback for clients list queries (string-based, legacy).
///
/// Takes a list of connection ID strings.
typedef ClientsStringCallback = void Function(List<String> clients);

/// Callback for packet operations that may receive a response value.
///
/// Takes an optional value parameter from packet handling.
/// Used in engine packet processing.
typedef PacketCallback = void Function(Object? value);

/// Generic callback for packet send operations.
///
/// No parameters, called when packet is sent.
typedef PacketSentCallback = void Function();

/// Callback for cleanup operations.
///
/// No parameters, called during cleanup.
typedef CleanupCallback = void Function();

/// Callback with no parameters and no return value.
typedef VoidCallback = void Function();

/// Callback for operations that may fail with an error.
///
/// Takes an optional error parameter. If null, operation succeeded.
typedef ErrorableCallback = void Function(Object? error);

/// Callback for data events.
///
/// Takes data of any type (will be refined with EventData when integrated).
typedef DataCallback = void Function(Object? data);

/// Callback for decoded packet events.
///
/// Takes a decoded packet (will be typed as SocketIOPacket when integrated).
typedef DecodedPacketCallback = void Function(Object packet);

/// Callback for transport events.
///
/// Takes transport-specific data.
typedef TransportCallback = void Function(Object? data);

/// Callback for broadcast operations.
///
/// No parameters, called after broadcast completes.
typedef BroadcastCallback = void Function();

/// Callback for room join/leave operations.
///
/// Takes an optional error if operation failed.
typedef RoomOperationCallback = void Function(Object? error);

/// Callback for namespace operations.
///
/// Takes a namespace instance (will be typed when Namespace class is available).
typedef NamespaceCallback = void Function(Object namespace);

/// Callback for adapter operations.
///
/// Generic callback for adapter-specific operations.
typedef AdapterCallback = void Function(Object? data);

/// Callback for handshake completion.
///
/// Takes handshake data (will be typed as HandshakeData when available).
typedef HandshakeCallback = void Function(Object handshake);

/// Callback for event emission.
///
/// Takes optional error and response data.
typedef EmitCallback = void Function(Object? error, List<Object?>? response);
