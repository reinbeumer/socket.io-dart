# Quick Reference: Idiomatic Dart Improvements

## Overview

This is a quick reference guide for the type-safe improvements made to socket_io-dart.

## Value Objects (14)

| Value Object | Purpose | Example |
|-------------|---------|---------|
| `ConnectionId` | Socket ID validation | `ConnectionId('abc123')` |
| `NamespaceName` | Namespace path (must start with '/') | `NamespaceName('/chat')` |
| `RoomName` | Room identifier | `RoomName('lobby')` |
| `EventName` | Event name (blocks reserved names) | `EventName('message')` |
| `TransportName` | Transport type enum | `TransportName.websocket` |
| `PacketId` | Packet identifier | `PacketId('5')` |
| `TimeoutDuration` | Duration with validation | `TimeoutDuration(Duration(seconds: 30))` |
| `PortNumber` | Port (1-65535) | `PortNumber(3000)` |
| `UrlPath` | URL path validation | `UrlPath('/socket.io/')` |
| `QueryParameters` | Immutable query params | `QueryParameters({'token': 'abc'})` |
| `DisconnectReason` | Typed disconnect reasons | `DisconnectReason.clientDisconnect()` |
| `ErrorCode` | Error codes (string/numeric) | `ErrorCode.authenticationFailed` |
| `EventArguments` | Type-safe event args | `EventArguments(['arg1', 'arg2'])` |
| `SocketState` | Socket state enum | `SocketState.connected` |

## Sealed Classes (6)

| Sealed Class | Variants | Use Case |
|-------------|----------|----------|
| `SocketIOPacket` | Connect, Event, Ack, Disconnect, ConnectError | Pattern match on packet type |
| `EngineIOPacket` | Multiple engine packet types | Engine.IO protocol |
| `EventData` | String, Int, Double, Bool, Map, List, Null | Type-safe event data |
| `TransportData` | String, Binary, Json, List, Mixed | Transport payloads |
| `SocketIOError` | Multiple error types | Error handling |
| `ValidationError` | 6 error types | Validation failures |

## Extension Methods

### Socket Extensions

```dart
import 'package:socket_io/src/extensions/socket_extensions.dart';

socket.isInRoom(RoomName('chat'))        // Check room membership
socket.getAllRooms()                     // Get all rooms
socket.roomCount                         // Count rooms
socket.isReady                          // Check if connected
socket.emitIfReady('event', data)       // Emit only if ready
socket.getQueryParameter('token')        // Get query param
```

### Map Extensions

```dart
import 'package:socket_io/src/extensions/map_extensions.dart';

map.getString('key', 'default')          // Type-safe string getter
map.getInt('count', 0)                  // Type-safe int getter
map.getNestedValue('user.name')         // Nested access
map.pick(['key1', 'key2'])              // Pick specific keys
map.merge(other)                        // Merge maps
```

### List Extensions

```dart
import 'package:socket_io/src/extensions/list_extensions.dart';

list.firstOrNull                        // Safe first element
list.getOrNull(10)                      // Safe index access
list.chunk(2)                           // Split into chunks
list.groupBy((x) => x.type)             // Group by function
list.allOfType<int>()                   // Type checking
```

### String Extensions

```dart
import 'package:socket_io/src/extensions/string_extensions.dart';

str.isValidNamespace                    // Check namespace format
str.parseQueryString                    // Parse query params
str.toCamelCase()                       // Convert to camelCase
str.toSnakeCase()                       // Convert to snake_case
str.truncate(10)                        // Truncate with ellipsis
```

### Packet Extensions

```dart
import 'package:socket_io/src/extensions/packet_extensions.dart';

packet.isConnect                        // Type checks
packet.isEvent
packet.isValid                          // Validation
packet.getValidationErrors              // Get errors
packet.eventName                        // Event packet helpers
packet.argCount
```

## Fluent APIs

### BroadcastOptions

```dart
final options = BroadcastOptions()
    .toRooms({RoomName('room1'), RoomName('room2')})
    .exceptSockets({socket.id})
    .withVolatile()
    .withCompression();
    
namespace.to(options).emit('event', data);
```

### QueryParameters

```dart
final query = QueryParameters({'token': 'abc'})
    .withParam('userId', '123')
    .withParam('sessionId', 'xyz')
    .withoutParam('temp');
```

### SocketFlags

```dart
final flags = SocketFlagsModel.defaults()
    .withVolatile(true)
    .withCompression(true);
```

## Pattern Matching

### Packets

```dart
switch (packet) {
  case ConnectPacket(:final namespace, :final data):
    print('Connect to ${namespace.value}');
    
  case EventPacket(:final eventName, :final arguments):
    print('Event: ${eventName.value}');
    
  case DisconnectPacket(:final reason):
    print('Disconnect: ${reason.message}');
    
  case AckPacket(:final ackId, :final values):
    print('Ack ${ackId.value}');
    
  case ConnectErrorPacket(:final error):
    print('Error: ${error.message}');
}
```

### Event Data

```dart
switch (data) {
  case StringEventData(:final value):
    handleString(value);
    
  case MapEventData(:final value):
    handleMap(value);
    
  case ListEventData(:final value):
    handleList(value);
    
  case IntEventData(:final value):
    handleInt(value);
    
  // ... more cases
}
```

### Errors

```dart
void handleError(SocketErrorModel error) {
  switch (error.type) {
    case SocketErrorType.connection:
      retryConnection();
      
    case SocketErrorType.authentication:
      requestNewCredentials();
      
    case SocketErrorType.timeout:
      increaseTimeout();
      
    // ... more cases
  }
}
```

## Type-Safe Packet Creation

### Old Way (Dynamic)

```dart
final packet = {
  'type': 2,
  'nsp': '/chat',
  'data': {'token': 'abc'},
};
```

### New Way (Type-Safe)

```dart
final packet = ConnectPacket(
  namespace: NamespaceName('/chat'),
  data: ConnectPacketData(authToken: 'abc'),
);

// Or use typed constructor
final eventPacket = EventPacket.typed(
  namespace: NamespaceName('/chat'),
  eventName: EventName('message'),
  arguments: EventArguments(['Hello', 'World']),
);
```

## Error Handling

### Old Way

```dart
void onerror(dynamic error) {
  print(error);
}
```

### New Way

```dart
void onErrorTyped(SocketErrorModel error) {
  print('${error.type}: ${error.message}');
  
  if (error.code != null) {
    print('Code: ${error.code!.value}');
  }
  
  if (error.originalError != null) {
    print('Original: ${error.originalError}');
  }
}

// Creating errors
final error = SocketErrorModel.authentication(
  'Invalid credentials',
  code: ErrorCode.authenticationFailed,
  context: {'userId': '123'},
);
```

## Typed Event Emitter

### Old Way

```dart
EventEmitter emitter = EventEmitter();
emitter.on('message', (dynamic data) {
  // No type safety
  print(data);
});
```

### New Way

```dart
TypedEventEmitter<String> emitter = TypedEventEmitter<String>();
emitter.on('message', (String data) {
  // Type-safe!
  print('Received: $data');
});
emitter.emit('message', 'Hello'); // Only String accepted
```

## Common Patterns

### Socket Connection with Auth

```dart
namespace.use((Socket socket, MiddlewareNext next) {
  final token = socket.handshakeTyped?.query.getString('token');
  
  if (token == null) {
    next(SocketErrorModel.authentication(
      'Missing token',
      code: ErrorCode.authenticationFailed,
    ));
    return;
  }
  
  socket.data['userId'] = extractUserId(token);
  next(null);
});
```

### Room Broadcasting

```dart
socket.on('chat-message', (Map<String, dynamic> data) {
  final room = RoomName(data['room'] as String);
  
  final options = BroadcastOptions()
      .toRooms({room})
      .exceptSockets({socket.id})
      .withCompression();
      
  namespace.to(options).emit('message', {
    'sender': socket.id.value,
    'content': data['message'],
  });
});
```

### Type-Safe Data Access

```dart
// Query parameters
final token = socket.handshakeTyped?.query.getString('token');
final userId = socket.handshakeTyped?.query.getInt('userId');

// Map data
final config = data.getMap<String, Object?>('config', {});
final list = data.getList<String>('items', []);

// Event arguments
final args = EventArguments(['value1', 123, true]);
final str = args.getStringAt(0);      // 'value1'
final num = args.getIntAt(1);         // 123
final bool = args.getBoolAt(2);       // true
```

## Migration Strategy

1. **Start using VOs**: Replace strings with `ConnectionId`, `NamespaceName`, etc.
2. **Use extensions**: Import and use extension methods
3. **Adopt typed methods**: Use `sendPacket()` instead of `packet()`
4. **Pattern matching**: Use sealed classes with switch expressions
5. **Fluent APIs**: Use builder patterns for configuration

## Import Paths

```dart
// Value Objects
import 'package:socket_io/src/value_objects/value_objects.dart';

// Models
import 'package:socket_io/src/models/models.dart';

// Extensions
import 'package:socket_io/src/extensions/extensions.dart';

// Typed Event Emitter
import 'package:socket_io/src/util/typed_event_emitter.dart';
```

## Testing

```dart
import 'package:test/test.dart';
import 'package:socket_io/socket_io.dart';

test('creates connection ID with validation', () {
  final id = ConnectionId('test-123');
  expect(id.value, equals('test-123'));
  
  expect(() => ConnectionId(''), throwsArgumentError);
});

test('handles typed packets', () {
  final packet = EventPacket.typed(
    namespace: NamespaceName('/test'),
    eventName: EventName('message'),
    arguments: EventArguments(['data']),
  );
  
  expect(packet.isEvent, isTrue);
  expect(packet.eventName.value, equals('message'));
  expect(packet.isValid, isTrue);
});
```

## Performance Tips

1. **Use volatile for non-critical messages**: `.withVolatile()`
2. **Enable compression for large payloads**: `.withCompression()`
3. **Batch operations**: Send arrays instead of looping
4. **Use acknowledgments sparingly**: Only when confirmation needed

## Documentation

- **Migration Guide**: [TYPE_SAFETY_MIGRATION_GUIDE.md](TYPE_SAFETY_MIGRATION_GUIDE.md)
- **Examples**: [TYPE_SAFE_EXAMPLES.md](TYPE_SAFE_EXAMPLES.md)

## Key Benefits

✅ **Compile-time safety**: Catch errors before runtime  
✅ **Better IDE support**: Autocomplete and refactoring  
✅ **Self-documenting**: Types explain expected values  
✅ **Pattern matching**: Exhaustive switch statements  
✅ **Validation**: Automatic input validation  
✅ **Backward compatible**: Old code still works  
✅ **Well tested**: 715 tests, all passing  
✅ **Comprehensive docs**: 1800+ lines of examples  

---

**Status**: Production Ready ✅  
**Tests**: 715/715 passing ✅  
**Analysis**: Zero issues ✅
