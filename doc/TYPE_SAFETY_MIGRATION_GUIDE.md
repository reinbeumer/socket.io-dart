# Type Safety Migration Guide

This guide helps you migrate from dynamic types to type-safe alternatives in the socket_io-dart library.

## Table of Contents

1. [Value Objects](#value-objects)
2. [Domain Models](#domain-models)
3. [Packet Types](#packet-types)
4. [Event Handling](#event-handling)
5. [Configuration](#configuration)
6. [Extensions](#extensions)

## Value Objects

### ConnectionId

**Before:**
```dart
String socketId = 'abc123';
// No validation, any string accepted
```

**After:**
```dart
import 'package:socket_io/src/value_objects/connection_id_vo.dart';

// With validation
final ConnectionId socketId = ConnectionId('abc123');
print(socketId.value); // 'abc123'

// Safe creation with error handling
final ConnectionId? safeId = ConnectionId.tryParse('');
if (safeId == null) {
  print('Invalid connection ID');
}
```

### NamespaceName

**Before:**
```dart
String namespace = '/chat';
// No validation for format
```

**After:**
```dart
import 'package:socket_io/src/value_objects/namespace_name_vo.dart';

// With validation (must start with '/')
final NamespaceName namespace = NamespaceName('/chat');
print(namespace.value); // '/chat'
print(namespace.isRoot); // false

// Try parse for safe creation
final NamespaceName? ns = NamespaceName.tryParse('invalid');
// Returns null - doesn't start with '/'
```

### RoomName

**Before:**
```dart
String room = 'room1';
// No validation
```

**After:**
```dart
import 'package:socket_io/src/value_objects/room_name_vo.dart';

final RoomName room = RoomName('room1');
print(room.value); // 'room1'

// Common rooms available as constants
final RoomName broadcastRoom = RoomName.broadcast;
```

### EventName

**Before:**
```dart
String event = 'message';
// Could accidentally use reserved names
```

**After:**
```dart
import 'package:socket_io/src/value_objects/event_name_vo.dart';

final EventName event = EventName('message');

// Validates against reserved names
final EventName? invalid = EventName.tryParse('connect'); // null - reserved name

// Check if event is custom
if (event.isCustomEvent) {
  print('User-defined event');
}
```

### QueryParameters

**Before:**
```dart
Map<String, dynamic>? query = {'token': 'abc', 'userId': '123'};
// Mutable, no type safety
```

**After:**
```dart
import 'package:socket_io/src/value_objects/query_parameters_vo.dart';

// Immutable and type-safe
final QueryParameters query = QueryParameters({
  'token': 'abc',
  'userId': '123',
});

// Type-safe getters
final String? token = query.getString('token');
final int? userId = query.getInt('userId');

// Fluent API for building
final QueryParameters newQuery = query
    .withParam('sessionId', 'xyz')
    .withoutParam('token');

// Parse from string
final QueryParameters parsed = QueryParameters.fromString('token=abc&userId=123');
```

### DisconnectReason

**Before:**
```dart
String reason = 'client disconnect';
// String literals, typo-prone
```

**After:**
```dart
import 'package:socket_io/src/value_objects/disconnect_reason_vo.dart';

// Type-safe enum
final DisconnectReasonType reason = DisconnectReasonType.clientDisconnect;

// Or create from DisconnectReason VO
final DisconnectReason disconnectReason = DisconnectReason.clientNamespaceDisconnect();

print(disconnectReason.message); // 'client namespace disconnect'
print(disconnectReason.type); // DisconnectReasonType.clientDisconnect
print(disconnectReason.isClientInitiated); // true
```

### ErrorCode

**Before:**
```dart
dynamic errorCode = 1001; // or '1001' or 'AUTH_ERROR'
// Inconsistent types
```

**After:**
```dart
import 'package:socket_io/src/value_objects/error_code_vo.dart';

// Supports both numeric and string codes
final ErrorCode numericCode = ErrorCode.numeric(1001);
final ErrorCode stringCode = ErrorCode.string('AUTH_ERROR');

// Predefined common codes
final ErrorCode connectionError = ErrorCode.connectionFailed;
final ErrorCode authError = ErrorCode.authenticationFailed;

// Type checking
if (numericCode.isNumeric) {
  print('Numeric code: ${numericCode.numericValue}');
}
```

### EventArguments

**Before:**
```dart
List<dynamic> args = ['Hello', 123, {'key': 'value'}];
// No type safety
```

**After:**
```dart
import 'package:socket_io/src/value_objects/event_arguments_vo.dart';

// Type-safe wrapper
final EventArguments args = EventArguments(['Hello', 123, {'key': 'value'}]);

// Type-safe access
final String? first = args.getStringAt(0); // 'Hello'
final int? second = args.getIntAt(1); // 123
final Map<String, dynamic>? third = args.getMapAt(2);

// Safe operations
final EventArguments subset = args.take(2);
final EventArguments appended = args.append('new value');
```

## Domain Models

### HandshakeData

**Before:**
```dart
Map<String, dynamic>? handshake = socket.handshake;
String? address = handshake?['address'];
// Untyped access
```

**After:**
```dart
import 'package:socket_io/src/models/handshake_data_models.dart';

final HandshakeData? handshake = socket.handshakeTyped;
if (handshake != null) {
  print(handshake.address); // Type-safe
  print(handshake.isSecure);
  print(handshake.headers.userAgent);
  
  // Query parameters as QueryParameters VO
  final String? token = handshake.query.getString('token');
}
```

### SocketData

**Before:**
```dart
Map<String, dynamic> data = socket.data;
data['userId'] = 123;
// No type safety
```

**After:**
```dart
import 'package:socket_io/src/models/socket_data_models.dart';

// Generic type-safe wrapper
final SocketData<int> userId = SocketData<int>('userId', 123);
socket.setData(userId);

final int? retrievedId = socket.getData<int>('userId');
```

### RoomMembership

**Before:**
```dart
Map<String, dynamic> rooms = socket.rooms;
bool inRoom = rooms.containsKey('room1');
```

**After:**
```dart
import 'package:socket_io/src/models/room_management_models.dart';

final RoomMembership membership = socket.roomMembershipTyped;

// Type-safe operations
if (membership.isInRoom(RoomName('room1'))) {
  print('In room');
}

final Set<RoomName> allRooms = membership.getAllRooms();
final int roomCount = membership.roomCount;
```

### SocketError

**Before:**
```dart
void onerror(dynamic error) {
  print(error); // Could be anything
}
```

**After:**
```dart
import 'package:socket_io/src/models/socket_error_models.dart';

void onErrorTyped(SocketErrorModel error) {
  switch (error.type) {
    case SocketErrorType.connection:
      print('Connection error: ${error.message}');
      break;
    case SocketErrorType.transport:
      print('Transport error: ${error.message}');
      if (error.context != null) {
        print('Context: ${error.context}');
      }
      break;
    case SocketErrorType.protocol:
      print('Protocol error: ${error.code}');
      break;
  }
}

// Create typed errors
final SocketErrorModel connectionError = SocketErrorModel.connection(
  'Connection refused',
  code: ErrorCode.connectionFailed,
);

final SocketErrorModel authError = SocketErrorModel.authentication(
  'Invalid credentials',
  context: {'userId': '123'},
);
```

## Packet Types

### Creating Packets

**Before:**
```dart
Map<String, dynamic> packet = {
  'type': 2, // CONNECT
  'nsp': '/chat',
  'data': {'token': 'abc'},
};
```

**After:**
```dart
import 'package:socket_io/src/models/packet_models.dart';
import 'package:socket_io/src/models/packet_data_models.dart';

// Type-safe packet creation
final ConnectPacket packet = ConnectPacket(
  namespace: NamespaceName('/chat'),
  data: ConnectPacketData(authToken: 'abc'),
);

// Event packet
final EventPacket eventPacket = EventPacket.typed(
  namespace: NamespaceName('/chat'),
  eventName: EventName('message'),
  arguments: EventArguments(['Hello', 'World']),
);

// Acknowledgment packet
final AckPacket ackPacket = AckPacket.typed(
  namespace: NamespaceName('/chat'),
  ackId: PacketId(5),
  values: EventArguments([true, 'success']),
);
```

### Handling Packets

**Before:**
```dart
void handlePacket(Map<String, dynamic> packet) {
  int type = packet['type'];
  if (type == 2) {
    // Handle connect
  }
}
```

**After:**
```dart
import 'package:socket_io/src/models/packet_models.dart';

void handlePacket(SocketIOPacket packet) {
  switch (packet) {
    case ConnectPacket(:final namespace, :final data):
      print('Connect to $namespace with ${data.authToken}');
      break;
    case EventPacket(:final eventName, :final arguments):
      print('Event $eventName with args: $arguments');
      break;
    case DisconnectPacket(:final reason):
      print('Disconnect: ${reason.message}');
      break;
    case AckPacket(:final ackId, :final values):
      print('Ack $ackId with values: $values');
      break;
    case ConnectErrorPacket(:final error):
      print('Connect error: ${error.message}');
      break;
  }
}
```

## Event Handling

### TypedEventEmitter

**Before:**
```dart
EventEmitter emitter = EventEmitter();
emitter.on('message', (dynamic data) {
  // No type safety
  print(data);
});
emitter.emit('message', 'Hello');
```

**After:**
```dart
import 'package:socket_io/src/util/typed_event_emitter.dart';

// Create strongly-typed event emitter
TypedEventEmitter<String> emitter = TypedEventEmitter<String>();

// Type-safe listener
emitter.on('message', (String data) {
  print('Received: $data'); // data is String
});

// Type-safe emission
emitter.emit('message', 'Hello'); // Only String accepted

// Or use EventData for complex types
TypedEventEmitter<EventData> complexEmitter = TypedEventEmitter<EventData>();
```

### Event Data Types

**Before:**
```dart
typedef SocketIOEventData = dynamic;
```

**After:**
```dart
import 'package:socket_io/src/models/event_data_models.dart';

// Sealed class with specific types
void handleEvent(EventData data) {
  switch (data) {
    case StringEventData(:final value):
      print('String: $value');
      break;
    case IntEventData(:final value):
      print('Int: $value');
      break;
    case MapEventData(:final value):
      print('Map: $value');
      break;
    case ListEventData(:final value):
      print('List: $value');
      break;
    case BoolEventData(:final value):
      print('Bool: $value');
      break;
    case DoubleEventData(:final value):
      print('Double: $value');
      break;
    case NullEventData():
      print('Null value');
      break;
  }
}

// Create event data
final EventData stringData = StringEventData('Hello');
final EventData mapData = MapEventData({'key': 'value'});
```

## Configuration

### Transport Configuration

**Before:**
```dart
Map<String, Object?> options = {
  'transports': ['websocket', 'polling'],
  'timeout': 20000,
};
```

**After:**
```dart
import 'package:socket_io/src/models/transport_models.dart';

final TransportConfigurationModel config = WebSocketConfigurationModel(
  secure: true,
  enableCompression: true,
  headers: {'Authorization': 'Bearer token'},
  timeout: TimeoutDuration(Duration(seconds: 20)),
);
```

### Broadcast Options

**Before:**
```dart
Map<String, bool> flags = {'volatile': true, 'compress': true};
```

**After:**
```dart
import 'package:socket_io/src/models/broadcast_options_models.dart';

// Fluent API
final BroadcastOptions options = BroadcastOptions()
    .toRooms({RoomName('room1'), RoomName('room2')})
    .exceptRooms({RoomName('room3')})
    .withVolatile()
    .withCompression();

// Use in broadcasts
namespace.to(options).emit('event', 'data');
```

### Socket Flags

**Before:**
```dart
Map<String, bool>? flags = {'volatile': true};
```

**After:**
```dart
import 'package:socket_io/src/models/socket_configuration_models.dart';

final SocketFlagsModel flags = SocketFlagsModel.defaults()
    .withVolatile(true)
    .withCompression(true);

if (flags.isVolatile) {
  print('Volatile message');
}
```

## Extensions

### Map Extensions

**Before:**
```dart
Map<String, dynamic> data = {'count': '123'};
int? count = data['count'] as int?; // Runtime error!
```

**After:**
```dart
import 'package:socket_io/src/extensions/map_extensions.dart';

Map<String, dynamic> data = {'count': '123'};

// Type-safe getters
final int count = data.getInt('count', 0); // Returns 0 if not int
final String? name = data.getStringOrNull('name'); // null if missing

// Nested access
final dynamic nested = data.getNestedValue('user.profile.name', 'Unknown');

// Map operations
final Map<String, dynamic> picked = data.pick(['count', 'name']);
final Map<String, dynamic> merged = data.merge({'extra': 'value'});
```

### List Extensions

**Before:**
```dart
List<dynamic> items = [1, 2, 3];
var first = items.isNotEmpty ? items[0] : null;
```

**After:**
```dart
import 'package:socket_io/src/extensions/list_extensions.dart';

List<int> items = [1, 2, 3];

// Safe access
final int? first = items.firstOrNull;
final int? atIndex = items.getOrNull(10); // null if out of bounds

// Chunking
final List<List<int>> chunks = items.chunk(2); // [[1, 2], [3]]

// Grouping
final Map<bool, List<int>> grouped = items.groupBy((x) => x % 2 == 0);

// Type checking for dynamic lists
List<dynamic> mixed = [1, 'two', 3];
final bool allInts = mixed.allOfType<int>(); // false
final List<int> onlyInts = mixed.whereType<int>(); // [1, 3]
```

### String Extensions

**Before:**
```dart
String namespace = '/chat';
bool isValid = namespace.startsWith('/');
```

**After:**
```dart
import 'package:socket_io/src/extensions/string_extensions.dart';

String namespace = '/chat';

// Validation
final bool isValid = namespace.isValidNamespace; // true

// Query parsing
final Map<String, String> query = 'token=abc&id=123'.parseQueryString;

// Case conversion
final String camelCase = 'user_name'.toCamelCase(); // 'userName'
final String snakeCase = 'userName'.toSnakeCase(); // 'user_name'

// Truncation
final String short = 'Long text'.truncate(5); // 'Long...'
```

### Socket Extensions

**Before:**
```dart
bool inRoom = socket.rooms.containsKey('room1');
```

**After:**
```dart
import 'package:socket_io/src/extensions/socket_extensions.dart';

// Room operations
final bool inRoom = socket.isInRoom(RoomName('room1'));
final Set<RoomName> rooms = socket.getAllRooms();
final int count = socket.roomCount;

// State queries
final SocketState state = socket.state;
if (socket.isReady) {
  socket.emitIfReady('event', 'data');
}

// Query parameters
final String? token = socket.getQueryParameter('token');
```

### Packet Extensions

**Before:**
```dart
Map<String, dynamic> packet = {'type': 2};
bool isConnect = packet['type'] == 2;
```

**After:**
```dart
import 'package:socket_io/src/extensions/packet_extensions.dart';

SocketIOPacket packet = ConnectPacket(...);

// Type checking
if (packet.isConnect) {
  print('Connect packet');
}

// Validation
if (packet.isValid) {
  print('Valid packet');
} else {
  final List<String> errors = packet.getValidationErrors;
  print('Errors: $errors');
}

// Event packet helpers
if (packet is EventPacket) {
  print('Event: ${packet.eventName}');
  print('Args: ${packet.eventArgs}');
  print('Count: ${packet.argCount}');
}
```

## Best Practices

### 1. Use Value Objects for Validation

Always use value objects to ensure data validity:

```dart
// ❌ Bad
String socketId = getUserInput(); // No validation

// ✅ Good
final ConnectionId? socketId = ConnectionId.tryParse(getUserInput());
if (socketId != null) {
  // Use socketId.value
}
```

### 2. Prefer Sealed Classes for Union Types

Use pattern matching with sealed classes:

```dart
// ✅ Good
void handlePacket(SocketIOPacket packet) {
  switch (packet) {
    case ConnectPacket():
      // Handle connect
    case EventPacket():
      // Handle event
    // Compiler ensures all cases handled
  }
}
```

### 3. Use Extensions for Cleaner Code

```dart
// ❌ Bad
if (socket.rooms.containsKey('room1')) {
  socket.emit('event', 'data');
}

// ✅ Good
if (socket.isInRoom(RoomName('room1'))) {
  socket.emitIfReady('event', 'data');
}
```

### 4. Build Configurations Fluently

```dart
// ✅ Good
final BroadcastOptions options = BroadcastOptions()
    .toRooms({RoomName('room1')})
    .withVolatile()
    .withCompression();
```

### 5. Handle Errors with Typed Models

```dart
// ✅ Good
void onError(SocketErrorModel error) {
  logger.error('${error.type}: ${error.message}', error: error.originalError);
}
```

## Gradual Migration Strategy

You can adopt these improvements gradually:

1. **Start with Value Objects**: Replace string literals with VOs
2. **Update Configuration**: Use typed configuration models
3. **Add Type-Safe Listeners**: Use TypedEventEmitter where possible
4. **Migrate to Typed Packets**: Use the `.typed()` constructors
5. **Use Extensions**: Import and use extension methods for cleaner code

Most changes are backward compatible - the old APIs still work alongside the new type-safe alternatives.

## Testing Type-Safe Code

```dart
import 'package:test/test.dart';
import 'package:socket_io/socket_io.dart';

void main() {
  group('Type-safe socket operations', () {
    test('creates connection ID with validation', () {
      final ConnectionId id = ConnectionId('test-123');
      expect(id.value, equals('test-123'));
      
      expect(() => ConnectionId(''), throwsArgumentError);
    });
    
    test('handles typed packets', () {
      final EventPacket packet = EventPacket.typed(
        namespace: NamespaceName('/test'),
        eventName: EventName('message'),
        arguments: EventArguments(['data']),
      );
      
      expect(packet.isEvent, isTrue);
      expect(packet.eventName.value, equals('message'));
    });
  });
}
```

## Further Reading

- [Value Objects in DDD](https://martinfowler.com/bliki/ValueObject.html)
- [Dart Sealed Classes](https://dart.dev/language/class-modifiers#sealed)
- [Effective Dart: Design](https://dart.dev/guides/language/effective-dart/design)
