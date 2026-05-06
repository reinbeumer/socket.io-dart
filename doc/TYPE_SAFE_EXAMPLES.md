# Type-Safe API Examples

This document provides practical examples of using the type-safe API in socket_io-dart.

> NOTE
> This document contains historical examples and may be partially out of sync
> with the current exported API. Use these examples as patterns, but verify
> symbols against the current public surface in `lib/socket_io.dart` and the
> runnable files under `example/`.

## Table of Contents

1. [Basic Socket Connection](#basic-socket-connection)
2. [Room Management](#room-management)
3. [Event Handling](#event-handling)
4. [Packet Operations](#packet-operations)
5. [Error Handling](#error-handling)
6. [Middleware](#middleware)
7. [Broadcasting](#broadcasting)
8. [Configuration](#configuration)

## Basic Socket Connection

### Simple Connection with Type Safety

```dart
import 'package:socket_io/socket_io.dart';

void main() {
  // Create server
  final Server server = Server();
  
  // Type-safe namespace creation
  final Namespace namespace = server.of(NamespaceName('/chat'));
  
  // Type-safe connection handler
  namespace.onTyped((Socket socket) {
    print('Client connected: ${socket.id.value}');
    
    // Access typed handshake data
    final HandshakeData? handshake = socket.handshakeTyped;
    if (handshake != null) {
      print('Connected from: ${handshake.address}');
      print('User agent: ${handshake.headers.userAgent}');
      
      // Type-safe query parameter access
      final String? token = handshake.query.getString('token');
      if (token != null) {
        print('Auth token: $token');
      }
    }
    
    // Handle disconnection
    socket.on('disconnect', (String reason) {
      print('Client disconnected: $reason');
    });
  });
  
  server.listen(3000);
}
```

### Connection with Authentication

```dart
import 'package:socket_io/socket_io.dart';

void setupAuthenticatedNamespace(Server server) {
  final Namespace namespace = server.of(NamespaceName('/secure'));
  
  // Add middleware for authentication
  namespace.use((Socket socket, MiddlewareNext next) {
    final HandshakeData? handshake = socket.handshakeTyped;
    final String? token = handshake?.query.getString('token');
    
    if (token == null || !isValidToken(token)) {
      // Create typed error
      final SocketErrorModel authError = SocketErrorModel.authentication(
        'Invalid authentication token',
        code: ErrorCode.authenticationFailed,
      );
      next(authError);
      return;
    }
    
    // Store user data in socket
    final String userId = extractUserId(token);
    socket.data['userId'] = userId;
    
    next(null);
  });
  
  namespace.onTyped((Socket socket) {
    final String userId = socket.data['userId'] as String;
    print('Authenticated user connected: $userId');
  });
}

bool isValidToken(String token) {
  // Your validation logic
  return token.isNotEmpty;
}

String extractUserId(String token) {
  // Your extraction logic
  return 'user123';
}
```

## Room Management

### Type-Safe Room Operations

```dart
import 'package:socket_io/socket_io.dart';

void setupRoomManagement(Socket socket) {
  // Join rooms with type safety
  final RoomName chatRoom = RoomName('chat-general');
  final RoomName userRoom = RoomName('user-${socket.id.value}');
  
  socket.join(chatRoom);
  socket.join(userRoom);
  
  // Check room membership using extension
  if (socket.isInRoom(chatRoom)) {
    print('Socket is in chat room');
  }
  
  // Get all rooms
  final Set<RoomName> rooms = socket.getAllRooms();
  print('Socket is in ${rooms.length} rooms');
  
  // List room names
  for (final RoomName room in rooms) {
    print('Room: ${room.value}');
  }
  
  // Leave room
  socket.leave(chatRoom);
  
  // Check room count
  print('Now in ${socket.roomCount} rooms');
}
```

### Room-Based Broadcasting

```dart
import 'package:socket_io/socket_io.dart';

void setupChatRooms(Namespace namespace) {
  namespace.onTyped((Socket socket) {
    // Handle join room event
    socket.on('join-room', (String roomName) {
      final RoomName room = RoomName(roomName);
      socket.join(room);
      
      // Broadcast to room with type-safe options
      final BroadcastOptions options = BroadcastOptions()
          .toRooms({room})
          .exceptSockets({socket.id});
      
      namespace.to(options).emit(
        'user-joined',
        {'userId': socket.data['userId'], 'room': roomName},
      );
      
      // Send confirmation to sender
      socket.emit('room-joined', {'room': roomName});
    });
    
    // Handle leave room event
    socket.on('leave-room', (String roomName) {
      final RoomName room = RoomName(roomName);
      socket.leave(room);
      
      // Notify room
      namespace.to(BroadcastOptions().toRooms({room})).emit(
        'user-left',
        {'userId': socket.data['userId'], 'room': roomName},
      );
    });
  });
}
```

## Event Handling

### Type-Safe Event Emission

```dart
import 'package:socket_io/socket_io.dart';

void setupTypedEvents(Socket socket) {
  // Emit with EventName and EventArguments
  final EventName messageEvent = EventName('message');
  final EventArguments args = EventArguments(['Hello', 'World']);
  
  socket.emitTyped(messageEvent, args);
  
  // Emit with acknowledgment
  socket.emitWithAck('request', ['data'], (List<Object?> response) {
    // Type-safe response handling
    final EventArguments responseArgs = EventArguments(response);
    final bool? success = responseArgs.getBoolAt(0);
    final String? message = responseArgs.getStringAt(1);
    
    if (success == true) {
      print('Request successful: $message');
    } else {
      print('Request failed: $message');
    }
  });
  
  // Emit if socket is ready
  if (socket.isReady) {
    socket.emitIfReady('status', 'online');
  }
}
```

### Strongly-Typed Event Emitter

```dart
import 'package:socket_io/socket_io.dart';

class ChatMessage {
  final String sender;
  final String content;
  final DateTime timestamp;
  
  ChatMessage(this.sender, this.content, this.timestamp);
}

void useTypedEventEmitter() {
  // Create strongly-typed emitter
  final TypedEventEmitter<ChatMessage> chatEmitter = TypedEventEmitter<ChatMessage>();
  
  // Type-safe listener
  chatEmitter.on('message', (ChatMessage message) {
    print('[${message.timestamp}] ${message.sender}: ${message.content}');
  });
  
  // Type-safe emission
  final ChatMessage msg = ChatMessage('Alice', 'Hello!', DateTime.now());
  chatEmitter.emit('message', msg);
  
  // Once listener
  chatEmitter.once('welcome', (ChatMessage message) {
    print('Welcome message: ${message.content}');
  });
}
```

### Event Data Pattern Matching

```dart
import 'package:socket_io/socket_io.dart';

void handleEventData(EventData data) {
  // Pattern matching with sealed class
  switch (data) {
    case StringEventData(:final value):
      print('Received string: $value');
      handleStringMessage(value);
      
    case MapEventData(:final value):
      print('Received map: $value');
      handleStructuredData(value);
      
    case ListEventData(:final value):
      print('Received list with ${value.length} items');
      handleListData(value);
      
    case IntEventData(:final value):
      print('Received number: $value');
      handleNumericData(value);
      
    case BoolEventData(:final value):
      print('Received boolean: $value');
      handleBooleanFlag(value);
      
    case DoubleEventData(:final value):
      print('Received decimal: $value');
      handleDecimalValue(value);
      
    case NullEventData():
      print('Received null value');
      handleNullData();
  }
}

void handleStringMessage(String message) { /* ... */ }
void handleStructuredData(Map<String, Object?> data) { /* ... */ }
void handleListData(List<Object?> list) { /* ... */ }
void handleNumericData(int number) { /* ... */ }
void handleBooleanFlag(bool flag) { /* ... */ }
void handleDecimalValue(double value) { /* ... */ }
void handleNullData() { /* ... */ }
```

## Packet Operations

### Creating Type-Safe Packets

```dart
import 'package:socket_io/socket_io.dart';

void createPackets() {
  // Connect packet
  final ConnectPacket connectPacket = ConnectPacket(
    namespace: NamespaceName('/chat'),
    data: ConnectPacketData(
      authToken: 'abc123',
      clientVersion: '2.0.0',
      metadata: {'platform': 'dart'},
    ),
  );
  
  // Event packet
  final EventPacket eventPacket = EventPacket.typed(
    namespace: NamespaceName('/chat'),
    eventName: EventName('message'),
    arguments: EventArguments(['Hello', 'World']),
    ackId: PacketId(5),
  );
  
  // Acknowledgment packet
  final AckPacket ackPacket = AckPacket.typed(
    namespace: NamespaceName('/chat'),
    ackId: PacketId(5),
    values: EventArguments([true, 'Message received']),
  );
  
  // Disconnect packet
  final DisconnectPacket disconnectPacket = DisconnectPacket(
    namespace: NamespaceName('/chat'),
    reason: DisconnectReason.serverShutdown(),
  );
  
  // Error packet
  final ConnectErrorPacket errorPacket = ConnectErrorPacket(
    namespace: NamespaceName('/chat'),
    error: SocketErrorModel.authentication(
      'Invalid credentials',
      code: ErrorCode.authenticationFailed,
    ),
  );
}
```

### Packet Pattern Matching

```dart
import 'package:socket_io/socket_io.dart';

void handlePacket(SocketIOPacket packet) {
  // Exhaustive pattern matching with sealed class
  switch (packet) {
    case ConnectPacket(:final namespace, :final data):
      print('Connect to ${namespace.value}');
      if (data.authToken != null) {
        print('With auth token: ${data.authToken}');
      }
      
    case EventPacket(:final eventName, :final arguments, :final ackId):
      print('Event: ${eventName.value}');
      print('Arguments: ${arguments.values}');
      if (ackId != null) {
        print('Requires ack: ${ackId.value}');
      }
      
    case AckPacket(:final ackId, :final values):
      print('Ack for packet ${ackId.value}');
      print('Values: ${values.values}');
      
    case DisconnectPacket(:final namespace, :final reason):
      print('Disconnect from ${namespace.value}');
      print('Reason: ${reason.message}');
      if (reason.isClientInitiated) {
        print('Client initiated disconnect');
      }
      
    case ConnectErrorPacket(:final namespace, :final error):
      print('Connect error for ${namespace.value}');
      print('Error: ${error.message}');
      if (error.code != null) {
        print('Code: ${error.code!.value}');
      }
  }
}
```

### Packet Validation

```dart
import 'package:socket_io/socket_io.dart';

void validateAndProcessPacket(SocketIOPacket packet) {
  // Use packet extensions for validation
  if (!packet.isValid) {
    final List<String> errors = packet.getValidationErrors;
    print('Invalid packet: ${errors.join(', ')}');
    return;
  }
  
  // Check if serializable
  if (!packet.isSerializable) {
    print('Warning: Packet may not serialize correctly');
  }
  
  // Type-specific checks
  if (packet.isEvent) {
    final EventPacket eventPacket = packet as EventPacket;
    print('Event: ${eventPacket.eventName}');
    print('Arg count: ${eventPacket.argCount}');
    
    if (eventPacket.requiresAck) {
      print('Requires acknowledgment');
    }
  }
  
  // Process packet
  processValidPacket(packet);
}

void processValidPacket(SocketIOPacket packet) { /* ... */ }
```

## Error Handling

### Type-Safe Error Creation

```dart
import 'package:socket_io/socket_io.dart';

void createErrors() {
  // Connection error
  final SocketErrorModel connectionError = SocketErrorModel.connection(
    'Failed to connect to server',
    code: ErrorCode.connectionFailed,
    context: {'host': 'localhost', 'port': 3000},
  );
  
  // Transport error
  final SocketErrorModel transportError = SocketErrorModel.transport(
    'WebSocket connection failed',
    code: ErrorCode.transportError,
    originalError: Exception('Connection refused'),
  );
  
  // Protocol error
  final SocketErrorModel protocolError = SocketErrorModel.protocol(
    'Invalid packet format',
    code: ErrorCode.numeric(4000),
  );
  
  // Authentication error
  final SocketErrorModel authError = SocketErrorModel.authentication(
    'Invalid credentials',
    code: ErrorCode.authenticationFailed,
    context: {'userId': 'user123'},
  );
  
  // Timeout error
  final SocketErrorModel timeoutError = SocketErrorModel.timeout(
    'Connection timeout',
    timeout: TimeoutDuration(Duration(seconds: 30)),
  );
  
  // Generic error
  final SocketErrorModel genericError = SocketErrorModel.generic(
    'Unknown error occurred',
  );
}
```

### Error Handling Patterns

```dart
import 'package:socket_io/socket_io.dart';

void setupErrorHandling(Socket socket) {
  // Type-safe error handler
  socket.onErrorTyped((SocketErrorModel error) {
    // Pattern match on error type
    switch (error.type) {
      case SocketErrorType.connection:
        handleConnectionError(error);
        
      case SocketErrorType.transport:
        handleTransportError(error);
        
      case SocketErrorType.protocol:
        handleProtocolError(error);
        
      case SocketErrorType.authentication:
        handleAuthError(error);
        
      case SocketErrorType.timeout:
        handleTimeoutError(error);
        
      case SocketErrorType.generic:
        handleGenericError(error);
    }
    
    // Log error details
    logError(error);
  });
}

void handleConnectionError(SocketErrorModel error) {
  print('Connection error: ${error.message}');
  if (error.context != null) {
    print('Context: ${error.context}');
  }
  // Attempt reconnection
}

void handleTransportError(SocketErrorModel error) {
  print('Transport error: ${error.message}');
  if (error.originalError != null) {
    print('Original error: ${error.originalError}');
  }
  // Try different transport
}

void handleProtocolError(SocketErrorModel error) {
  print('Protocol error: ${error.message}');
  if (error.code != null) {
    print('Error code: ${error.code!.value}');
  }
}

void handleAuthError(SocketErrorModel error) {
  print('Auth error: ${error.message}');
  // Request new credentials
}

void handleTimeoutError(SocketErrorModel error) {
  print('Timeout error: ${error.message}');
  if (error.timeout != null) {
    print('Timeout duration: ${error.timeout!.duration}');
  }
}

void handleGenericError(SocketErrorModel error) {
  print('Generic error: ${error.message}');
}

void logError(SocketErrorModel error) {
  // Your logging implementation
}
```

## Middleware

### Type-Safe Middleware

```dart
import 'package:socket_io/socket_io.dart';

void setupMiddleware(Namespace namespace) {
  // Authentication middleware
  namespace.use((Socket socket, MiddlewareNext next) {
    final HandshakeData? handshake = socket.handshakeTyped;
    final String? token = handshake?.query.getString('token');
    
    if (token == null) {
      final SocketErrorModel error = SocketErrorModel.authentication(
        'Missing authentication token',
        code: ErrorCode.authenticationFailed,
      );
      next(error);
      return;
    }
    
    next(null);
  });
  
  // Logging middleware
  namespace.use((Socket socket, MiddlewareNext next) {
    print('Socket ${socket.id.value} connecting');
    final DateTime startTime = DateTime.now();
    
    next(null);
    
    final Duration elapsed = DateTime.now().difference(startTime);
    print('Connection setup took ${elapsed.inMilliseconds}ms');
  });
  
  // Rate limiting middleware
  final Map<String, int> requestCounts = <String, int>{};
  
  namespace.use((Socket socket, MiddlewareNext next) {
    final HandshakeData? handshake = socket.handshakeTyped;
    final String address = handshake?.address ?? 'unknown';
    
    final int count = (requestCounts[address] ?? 0) + 1;
    requestCounts[address] = count;
    
    if (count > 10) {
      final SocketErrorModel error = SocketErrorModel.generic(
        'Rate limit exceeded',
        code: ErrorCode.numeric(429),
      );
      next(error);
      return;
    }
    
    next(null);
  });
}
```

## Broadcasting

### Advanced Broadcasting

```dart
import 'package:socket_io/socket_io.dart';

void setupBroadcasting(Namespace namespace) {
  namespace.onTyped((Socket socket) {
    // Broadcast to specific rooms
    socket.on('broadcast-to-rooms', (Map<String, dynamic> data) {
      final List<String> roomNames = List<String>.from(data['rooms']);
      final Set<RoomName> rooms = roomNames.map((n) => RoomName(n)).toSet();
      
      final BroadcastOptions options = BroadcastOptions()
          .toRooms(rooms)
          .withVolatile(); // Don't buffer if client disconnected
      
      namespace.to(options).emit('room-broadcast', data['message']);
    });
    
    // Broadcast except specific sockets
    socket.on('broadcast-except', (Map<String, dynamic> data) {
      final List<String> excludeIds = List<String>.from(data['exclude']);
      final Set<ConnectionId> excludeSockets = 
          excludeIds.map((id) => ConnectionId(id)).toSet();
      
      final BroadcastOptions options = BroadcastOptions()
          .exceptSockets(excludeSockets)
          .withCompression(); // Compress data
      
      namespace.to(options).emit('targeted-broadcast', data['message']);
    });
    
    // Broadcast to all except sender
    socket.on('broadcast', (String message) {
      socket.broadcast.emit('message', message);
    });
    
    // Broadcast to specific room except sender
    socket.on('room-message', (Map<String, dynamic> data) {
      final RoomName room = RoomName(data['room']);
      final BroadcastOptions options = BroadcastOptions()
          .toRooms({room})
          .exceptSockets({socket.id});
      
      namespace.to(options).emit('room-message', {
        'sender': socket.id.value,
        'message': data['message'],
      });
    });
  });
}
```

## Configuration

### Server Configuration

```dart
import 'package:socket_io/socket_io.dart';

void configureServer() {
  final Server server = Server();
  
  // Configure transport
  final TransportConfigurationModel transportConfig = 
      WebSocketConfigurationModel(
    secure: true,
    enableCompression: true,
    maxHttpBufferSize: 1024 * 1024, // 1MB
    pingTimeout: TimeoutDuration(Duration(seconds: 60)),
    pingInterval: TimeoutDuration(Duration(seconds: 25)),
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST',
    },
  );
  
  // Use configuration (example - actual API may vary)
  // server.configure(transportConfig);
}
```

### Client Configuration

```dart
import 'package:socket_io/socket_io.dart';

void configureClient() {
  // Configure connection with query parameters
  final QueryParameters query = QueryParameters({
    'token': 'abc123',
    'userId': '456',
  });
  
  // Add more parameters
  final QueryParameters fullQuery = query
      .withParam('sessionId', 'xyz789')
      .withParam('version', '2.0');
  
  // Use in connection (example)
  // socket.connect(fullQuery);
}
```

## Complete Example: Chat Application

```dart
import 'dart:io';
import 'package:socket_io/socket_io.dart';

void main() {
  final Server server = Server();
  final Namespace chatNamespace = server.of(NamespaceName('/chat'));
  
  // Authentication middleware
  chatNamespace.use((Socket socket, MiddlewareNext next) {
    final HandshakeData? handshake = socket.handshakeTyped;
    final String? username = handshake?.query.getString('username');
    
    if (username == null || username.isEmpty) {
      next(SocketErrorModel.authentication(
        'Username required',
        code: ErrorCode.authenticationFailed,
      ));
      return;
    }
    
    socket.data['username'] = username;
    next(null);
  });
  
  // Connection handler
  chatNamespace.onTyped((Socket socket) {
    final String username = socket.data['username'] as String;
    print('$username connected');
    
    // Join general room
    final RoomName generalRoom = RoomName('general');
    socket.join(generalRoom);
    
    // Notify others
    socket.broadcast.emit('user-joined', {
      'username': username,
      'id': socket.id.value,
    });
    
    // Handle chat messages
    socket.on('chat-message', (Map<String, dynamic> data) {
      final String message = data['message'] as String;
      final String? roomName = data['room'] as String?;
      
      final Map<String, dynamic> messageData = {
        'username': username,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      if (roomName != null) {
        // Send to specific room
        final RoomName room = RoomName(roomName);
        final BroadcastOptions options = BroadcastOptions()
            .toRooms({room})
            .withCompression();
        chatNamespace.to(options).emit('chat-message', messageData);
      } else {
        // Send to all
        chatNamespace.emit('chat-message', messageData);
      }
    });
    
    // Handle room joining
    socket.on('join-room', (String roomName) {
      final RoomName room = RoomName(roomName);
      socket.join(room);
      socket.emit('room-joined', {'room': roomName});
      
      // Notify room members
      final BroadcastOptions options = BroadcastOptions()
          .toRooms({room})
          .exceptSockets({socket.id});
      chatNamespace.to(options).emit('user-joined-room', {
        'username': username,
        'room': roomName,
      });
    });
    
    // Handle disconnection
    socket.on('disconnect', (String reason) {
      print('$username disconnected: $reason');
      
      // Notify all users
      chatNamespace.emit('user-left', {
        'username': username,
        'reason': reason,
      });
    });
    
    // Error handling
    socket.onErrorTyped((SocketErrorModel error) {
      print('Error for $username: ${error.message}');
      
      if (error.type == SocketErrorType.authentication) {
        socket.disconnect();
      }
    });
  });
  
  server.listen(3000);
  print('Chat server listening on port 3000');
}
```

## Testing Examples

```dart
import 'package:test/test.dart';
import 'package:socket_io/socket_io.dart';

void main() {
  group('Type-safe socket operations', () {
    late Server server;
    late Namespace namespace;
    
    setUp(() {
      server = Server();
      namespace = server.of(NamespaceName('/test'));
    });
    
    tearDown(() {
      server.close();
    });
    
    test('creates connection ID with validation', () {
      final ConnectionId id = ConnectionId('test-123');
      expect(id.value, equals('test-123'));
      
      expect(() => ConnectionId(''), throwsArgumentError);
    });
    
    test('validates namespace names', () {
      final NamespaceName ns = NamespaceName('/test');
      expect(ns.value, equals('/test'));
      expect(ns.isRoot, isFalse);
      
      final NamespaceName root = NamespaceName.root;
      expect(root.isRoot, isTrue);
      
      expect(() => NamespaceName('invalid'), throwsArgumentError);
    });
    
    test('handles typed packets', () {
      final EventPacket packet = EventPacket.typed(
        namespace: NamespaceName('/test'),
        eventName: EventName('message'),
        arguments: EventArguments(['data']),
      );
      
      expect(packet.isEvent, isTrue);
      expect(packet.eventName.value, equals('message'));
      expect(packet.argCount, equals(1));
      expect(packet.isValid, isTrue);
    });
    
    test('manages rooms type-safely', () {
      final RoomMembership membership = RoomMembership.empty();
      final RoomName room = RoomName('test-room');
      
      final RoomMembership updated = membership.addRoom(room);
      expect(updated.isInRoom(room), isTrue);
      expect(updated.roomCount, equals(1));
      
      final RoomMembership removed = updated.removeRoom(room);
      expect(removed.isInRoom(room), isFalse);
      expect(removed.roomCount, equals(0));
    });
    
    test('creates typed errors', () {
      final SocketErrorModel error = SocketErrorModel.authentication(
        'Invalid token',
        code: ErrorCode.authenticationFailed,
      );
      
      expect(error.type, equals(SocketErrorType.authentication));
      expect(error.message, equals('Invalid token'));
      expect(error.code?.value, equals('auth_failed'));
    });
  });
}
```

## Performance Tips

### 1. Use Volatile for Non-Critical Messages

```dart
// For real-time updates where missing some is acceptable
final BroadcastOptions options = BroadcastOptions()
    .withVolatile();
namespace.to(options).emit('position-update', {'x': 10, 'y': 20});
```

### 2. Enable Compression for Large Payloads

```dart
final BroadcastOptions options = BroadcastOptions()
    .withCompression();
namespace.to(options).emit('large-data', largeObject);
```

### 3. Batch Operations

```dart
// Instead of emitting in a loop
final List<Map<String, dynamic>> updates = [...];
socket.emit('batch-update', updates);
```

### 4. Use Acknowledgments Sparingly

```dart
// Only use acks when you need confirmation
socket.emitWithAck('critical-operation', data, (response) {
  // Handle response
});
```

## Security Best Practices

### 1. Always Validate Input

```dart
socket.on('user-input', (dynamic data) {
  // Validate before using
  if (data is! Map<String, dynamic>) {
    socket.emit('error', 'Invalid data format');
    return;
  }
  
  final String? username = data['username'] as String?;
  if (username == null || username.length > 50) {
    socket.emit('error', 'Invalid username');
    return;
  }
  
  // Use validated data
  processUsername(username);
});

void processUsername(String username) { /* ... */ }
```

### 2. Implement Rate Limiting

```dart
final Map<String, int> rateLimits = <String, int>{};

namespace.use((Socket socket, MiddlewareNext next) {
  final String address = socket.handshakeTyped?.address ?? 'unknown';
  final int count = (rateLimits[address] ?? 0) + 1;
  
  if (count > 100) {
    next(SocketErrorModel.generic(
      'Rate limit exceeded',
      code: ErrorCode.numeric(429),
    ));
    return;
  }
  
  rateLimits[address] = count;
  next(null);
});
```

### 3. Sanitize Output

```dart
socket.on('message', (String message) {
  // Sanitize before broadcasting
  final String sanitized = sanitizeHtml(message);
  namespace.emit('message', sanitized);
});

String sanitizeHtml(String input) {
  // Your sanitization logic
  return input
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
```

## Debugging Tips

### 1. Enable Logging

```dart
import 'package:logging/logging.dart';

void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}
```

### 2. Validate Packets

```dart
void debugPacket(SocketIOPacket packet) {
  if (!packet.isValid) {
    print('Invalid packet:');
    for (final String error in packet.getValidationErrors) {
      print('  - $error');
    }
  }
  
  print('Packet type: ${packet.runtimeType}');
  print('Serializable: ${packet.isSerializable}');
}
```

### 3. Monitor Socket State

```dart
socket.on('state-change', (dynamic _) {
  print('Socket state: ${socket.state}');
  print('Is ready: ${socket.isReady}');
  print('Room count: ${socket.roomCount}');
  print('Rooms: ${socket.getAllRoomNames()}');
});
```

These examples demonstrate the full power of the type-safe API in socket_io-dart. Use them as templates for your own applications!
