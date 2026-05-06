# Architecture Documentation

**socket_io-dart** - Modern Socket.IO Server Implementation

This document describes the architectural patterns, design decisions, and code organization of the socket_io library.

---

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Directory Structure](#directory-structure)
3. [Core Concepts](#core-concepts)
4. [Type System & Value Objects](#type-system--value-objects)
5. [Domain Models](#domain-models)
6. [Extension Methods Pattern](#extension-methods-pattern)
7. [Sealed Classes & Pattern Matching](#sealed-classes--pattern-matching)
8. [Backward Compatibility Strategy](#backward-compatibility-strategy)
9. [Transport Layer](#transport-layer)
10. [Event System](#event-system)
11. [Testing Strategy](#testing-strategy)

---

## High-Level Architecture

socket_io follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                   Public API                         │
│              (Server, Socket, Namespace)             │
├─────────────────────────────────────────────────────┤
│                 Domain Layer                         │
│        (Models, Value Objects, Business Logic)       │
├─────────────────────────────────────────────────────┤
│                Transport Layer                       │
│        (WebSocket, Polling, JSONP Transports)        │
├─────────────────────────────────────────────────────┤
│                  Engine.IO Layer                     │
│          (Low-level connection management)           │
└─────────────────────────────────────────────────────┘
```

### Key Architectural Principles

1. **Type Safety First**: Extensive use of value objects, sealed classes, and typed models
2. **Dual API Pattern**: Backward compatibility with legacy API while providing modern typed alternatives
3. **Domain-Driven Design**: Rich domain models with business logic encapsulation
4. **Extension-based Utilities**: Non-intrusive functionality additions via extensions
5. **Event-Driven Architecture**: Observer pattern for real-time communication
6. **Adapter Pattern**: Pluggable room/namespace management

---

## Directory Structure

```
lib/
├── src/
│   ├── adapter/              # Room and namespace adapters
│   │   └── adapter.dart      # Default memory adapter
│   ├── constants/            # Shared constants
│   │   └── socket_events.dart
│   ├── engine/               # Engine.IO transport layer
│   │   ├── engine.dart       # Engine.IO server
│   │   ├── socket.dart       # Engine.IO socket
│   │   └── transport/        # Transport implementations
│   │       ├── polling_transport.dart
│   │       ├── websocket_transport.dart
│   │       ├── jsonp_transport.dart
│   │       └── transports.dart
│   ├── extensions/           # Extension methods
│   │   ├── duration_extensions.dart
│   │   ├── list_extensions.dart
│   │   ├── map_extensions.dart
│   │   ├── packet_extensions.dart
│   │   ├── socket_extensions.dart
│   │   └── string_extensions.dart
│   ├── models/              # Domain models (26+ files)
│   │   ├── packet_models.dart
│   │   ├── server_options_models.dart
│   │   ├── error_models.dart
│   │   ├── callbacks_models.dart
│   │   └── ... (20+ more)
│   ├── value_objects/       # Value objects (14 types)
│   │   ├── connection_id_vo.dart
│   │   ├── room_name_vo.dart
│   │   ├── event_name_vo.dart
│   │   └── ... (11 more)
│   ├── util/                # Utilities
│   │   └── event_emitter.dart
│   ├── client.dart          # Client connection handler
│   ├── namespace.dart       # Namespace management
│   ├── server.dart          # Socket.IO server
│   └── socket.dart          # Socket connection
└── socket_io.dart        # Public API exports

test/                        # Test suite (748 tests)
├── models/                  # Model tests
├── value_objects/           # Value object tests
└── ...
```

### Organization Principles

- **models/**: Rich domain models with business logic
- **value_objects/**: Immutable validated primitives
- **extensions/**: Utility methods organized by type
- **engine/**: Low-level transport and connection handling
- **adapter/**: Room and namespace management strategies

---

## Core Concepts

### 1. Server

The `Server` class is the main entry point:

```dart
final server = Server();
server.on('connection', (socket) {
  // Handle socket connection
});
server.listen(3000);
```

**Responsibilities:**
- Manages namespaces
- Handles client connections
- Configures transport options
- Provides adapter configuration

### 2. Namespace

Namespaces create separate communication channels:

```dart
final chatNamespace = server.of('/chat');
chatNamespace.on('connection', (socket) {
  // Chat-specific logic
});
```

**Responsibilities:**
- Isolates message routing
- Manages socket connections within namespace
- Applies middleware
- Manages rooms

### 3. Socket

Individual client connections:

```dart
socket.on('message', (data) {
  socket.emit('response', ['received']);
});
```

**Responsibilities:**
- Event emission and reception
- Room membership management
- Binary data handling
- Acknowledgment callbacks

### 4. Adapter

Manages rooms and broadcasts:

```dart
class Adapter {
  void add(String id, String room);
  void broadcast(Map packet, Map? opts);
  void clients(List<String>? rooms, ClientsCallback fn);
}
```

**Default:** In-memory adapter  
**Extensible:** Can implement Redis, MongoDB adapters

---

## Type System & Value Objects

### Philosophy

Value Objects provide **type safety** and **validation** at the boundaries:

```dart
// Instead of: String roomName
final room = RoomName('chatRoom');  // Validated, non-empty

// Instead of: int port  
final port = PortNumber(3000);  // Validated range 1-65535

// Instead of: String eventName
final event = EventName('message');  // No reserved names
```

### Value Object Catalog

| Value Object | Validation | Purpose |
|--------------|------------|---------|
| `ConnectionId` | Non-empty string | Socket connection identifier |
| `RoomName` | Non-empty string | Room identifier |
| `EventName` | No reserved names | Custom event names |
| `NamespaceName` | Starts with `/` | Namespace identifier |
| `PortNumber` | 1-65535 | Port validation |
| `TimeoutDuration` | Non-negative | Timeout configuration |
| `TransportName` | Valid transport type | Transport selection |
| `UrlPath` | Starts with `/` | URL path validation |
| `QueryParameters` | Key-value map | Type-safe query access |
| `ErrorCode` | Numeric or string | Error identification |
| `DisconnectReason` | Enum-based | Disconnect classification |
| `SocketState` | Enum-based | Connection state |
| `PacketId` | Non-empty | Packet identification |
| `EventArguments` | Type-safe list | Event data container |

### Value Object Pattern

```dart
class ConnectionId {
  final String value;
  
  // Private constructor
  const ConnectionId._(this.value);
  
  // Validated factory
  factory ConnectionId(String id) {
    if (id.isEmpty) {
      throw ArgumentError('Connection ID cannot be empty');
    }
    return ConnectionId._(id);
  }
  
  // Unchecked for trusted sources
  const ConnectionId.unchecked(this.value);
  
  @override
  bool operator ==(Object other) => 
      other is ConnectionId && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => value;
}
```

---

## Domain Models

### Model Categories

**1. Packet Models** (`packet_models.dart`)
- `SocketIOPacket` (sealed class)
- `ConnectPacket`, `DisconnectPacket`, `EventPacket`, `AckPacket`
- Type-safe packet construction

**2. Configuration Models**
- `ServerOptionsModel`: Server configuration
- `HandshakeDataModel`: Connection handshake data
- `SocketDataModel`: Per-socket data storage

**3. Error Models** (`error_models.dart`)
- `SocketIOError` (sealed class)
- `TransportErrorModel`, `ConnectionErrorModel`, `ValidationErrorModel`
- Typed error handling

**4. Transport Models**
- `TransportData` (sealed class)
- `StringTransportData`, `BinaryTransportData`, `JsonTransportData`

**5. Room & Broadcast Models**
- `RoomMembership`: Type-safe room tracking
- `BroadcastOptions`: Broadcast configuration
- `RoomFilter`: Room selection logic

### Sealed Class Pattern

Sealed classes enable **exhaustive pattern matching**:

```dart
sealed class SocketIOError implements Exception {
  String get type;
  String get message;
}

class TransportErrorModel extends SocketIOError { ... }
class ConnectionErrorModel extends SocketIOError { ... }
class ValidationErrorModel extends SocketIOError { ... }

// Exhaustive switch - compiler ensures all cases covered
void handleError(SocketIOError error) {
  switch (error) {
    case TransportErrorModel():
      // Handle transport error
    case ConnectionErrorModel():
      // Handle connection error
    case ValidationErrorModel():
      // Handle validation error
  }
  // Compiler error if any case is missing!
}
```

---

## Extension Methods Pattern

Extensions add utility methods **without modifying core classes**:

### Examples

**Packet Extensions** (`packet_extensions.dart`):
```dart
extension PacketExtensions on SocketIOPacket {
  bool get isConnect => type == CONNECT;
  bool get isDisconnect => type == DISCONNECT;
  bool get isEvent => type == EVENT || type == BINARY_EVENT;
  String get typeName { ... }
  String get description { ... }
}
```

**Map Extensions** (`map_extensions.dart`):
```dart
extension TypeSafeMapAccess on Map<String, dynamic> {
  T? getTyped<T>(String key) => this[key] as T?;
  String? getString(String key) => getTyped<String>(key);
  int? getInt(String key) => getTyped<int>(key);
  Map<String, dynamic>? getMap(String key) => 
      getTyped<Map<String, dynamic>>(key);
}
```

**Duration Extensions** (`duration_extensions.dart`):
```dart
extension DurationFormatting on Duration {
  String toReadableString() { ... }
  bool get isLongerThan(Duration other) { ... }
}
```

### Extension Benefits

✅ **Non-intrusive**: Don't modify original classes  
✅ **Organized**: Group related utilities  
✅ **Discoverable**: IDE auto-completion  
✅ **Type-safe**: Compile-time checking  
✅ **Testable**: Easy to unit test

---

## Sealed Classes & Pattern Matching

### Why Sealed Classes?

Dart 3.0 introduced sealed classes for **closed type hierarchies**:

```dart
sealed class TransportData {
  const TransportData();
}

final class StringTransportData extends TransportData {
  final String value;
  const StringTransportData(this.value);
}

final class BinaryTransportData extends TransportData {
  final List<int> bytes;
  const BinaryTransportData(this.bytes);
}

final class JsonTransportData extends TransportData {
  final Map<String, dynamic> data;
  const JsonTransportData(this.data);
}
```

### Benefits

1. **Exhaustive Checking**: Compiler ensures all cases handled
2. **No Default Case Needed**: All subtypes known at compile time
3. **Refactoring Safety**: Adding new subtype causes compile errors
4. **IDE Support**: Better auto-completion and hints

### Usage in socket_io

- `SocketIOPacket`: All packet types
- `SocketIOError`: All error types
- `TransportData`: All data formats
- `EventData`: All event data types
- `CookieConfig`: Enabled/disabled states
- `ValidationError`: All validation error types

---

## Backward Compatibility Strategy

### Dual API Pattern

The library maintains **two parallel APIs**:

**Legacy API** (for backward compatibility):
```dart
socket.on('message', (data) {
  final map = data as Map<String, dynamic>;
  print(map['text']);
});

socket.handshake['query'];  // Map<String, dynamic>
socket.data['userId'] = 123;  // Map<String, dynamic>
socket.acks[id] = callback;  // Map<String, Function>
```

**Modern Typed API**:
```dart
socket.on('message', (data) {
  final eventData = EventData.fromDynamic(data);
  if (eventData is MapEventData) {
    print(eventData.value['text']);
  }
});

socket.handshakeData?.query;  // QueryParameters
socket.socketData.set('userId', 123);  // SocketDataModel
socket.acksTyped[id] = callback;  // Map<String, AckCallback>
```

### Implementation Strategy

**Dual Fields**:
```dart
class Socket {
  // Legacy (kept for BC)
  Map<String, dynamic>? handshake;
  Map<String, dynamic> data = {};
  Map<String, Function> acks = {};
  
  // Modern typed (new)
  HandshakeDataModel? handshakeData;
  SocketDataModel socketData = SocketDataModel();
  Map<String, AckCallback> acksTyped = {};
}
```

**Synchronization**:
```dart
// Both APIs work with same underlying data
data = socketData.toMap();  // Sync old → new
socketData.fromMap(data);   // Sync new → old
```

### Migration Path

1. **Phase 1** (Current): Both APIs available
2. **Phase 2** (Future): Deprecate old API
3. **Phase 3** (Major version): Remove old API

---

## Transport Layer

### Transport Hierarchy

```
Transport (abstract)
├── WebSocketTransport    - Full-duplex, lowest latency
├── PollingTransport      - HTTP long-polling fallback
└── JSONPTransport        - Legacy browser support
```

### Transport Selection

**Client-driven** with server preferences:

```dart
final server = Server(options: {
  'transports': ['websocket', 'polling'],  // Preference order
});
```

**Automatic fallback**:
1. Try WebSocket
2. Fall back to Polling if WebSocket unavailable
3. Use JSONP for legacy browsers if needed

### Transport Interface

```dart
abstract class Transport {
  void send(List<Map<String, dynamic>> packets);
  void close();
  void onPacket(Map<String, dynamic> packet);
  void onClose();
}
```

### Engine.IO Integration

socket_io builds on **Engine.IO** for transport management:

```
Socket.IO (Application Protocol)
      ↓
  SocketIOPacket encoding/decoding
      ↓
Engine.IO (Transport Protocol)
      ↓
WebSocket | HTTP Polling | JSONP
```

---

## Event System

### EventEmitter Pattern

Core event system based on **Observer pattern**:

```dart
class EventEmitter {
  // Event → List of handlers
  HashMap<String, List<EventHandler>> _events;
  
  void on(String event, EventHandler handler) { ... }
  void once(String event, EventHandler handler) { ... }
  void emit(String event, [dynamic data]) { ... }
  void off(String event, [EventHandler? handler]) { ... }
}
```

### Event Flow

```
Client Event
    ↓
Transport.onPacket()
    ↓
Engine.Socket.onPacket()
    ↓
Client.onpacket()
    ↓
Socket.emit(eventName, data)
    ↓
User Handler
```

### Reserved Events

Defined in `SocketEvents.blacklisted`:
- `connect` / `connection`
- `disconnect`
- `error`
- `newListener`
- `removeListener`

Custom events **cannot** use these names (validated by `EventName` value object).

---

## Testing Strategy

### Test Organization

```
test/
├── models/                 # Domain model tests
│   ├── packet_models_test.dart
│   ├── error_models_test.dart
│   └── ... (15 more)
├── value_objects/          # Value object tests
│   ├── connection_id_vo_test.dart
│   ├── room_name_vo_test.dart
│   └── ... (12 more)
├── adapter_broadcast_models_test.dart
├── namespace_config_models_test.dart
└── typed_event_emitter_test.dart
```

### Testing Principles

1. **Unit Tests**: Every value object and model tested independently
2. **Property-Based**: Validation rules thoroughly tested
3. **Edge Cases**: Null, empty, invalid inputs
4. **Type Safety**: Ensure compile-time type checking works
5. **Backward Compatibility**: Both APIs tested

### Test Coverage

- **748 tests** across 34 test files
- **Value Objects**: 100% coverage of validation rules
- **Models**: Factory methods, equality, serialization
- **Extensions**: All utility methods tested
- **Error Handling**: All error types and factories

### Example Test Pattern

```dart
group('ConnectionId', () {
  test('creates valid ConnectionId from non-empty string', () {
    final id = ConnectionId('test-id');
    expect(id.value, equals('test-id'));
  });
  
  test('throws ArgumentError for empty string', () {
    expect(() => ConnectionId(''), throwsArgumentError);
  });
  
  test('equality works correctly', () {
    final id1 = ConnectionId('test');
    final id2 = ConnectionId('test');
    expect(id1, equals(id2));
  });
  
  test('hashCode works correctly', () {
    final id1 = ConnectionId('test');
    final id2 = ConnectionId('test');
    expect(id1.hashCode, equals(id2.hashCode));
  });
});
```

---

## Key Design Patterns

### 1. Factory Pattern

Used extensively for packet creation:

```dart
// Factory methods for different packet types
EventPacket.typed(eventName: 'message', data: ...);
AckPacket.typed(id: '123', data: ...);
ConnectPacket.typed(namespace: '/chat');
```

### 2. Builder Pattern

Complex object construction:

```dart
HandshakeDataBuilder()
  .headers(request.headers)
  .time(DateTime.now())
  .address(remoteAddress)
  .secure(true)
  .build();
```

### 3. Adapter Pattern

Pluggable room/namespace management:

```dart
abstract class Adapter {
  void add(String id, String room);
  void broadcast(Map packet, Map? opts);
}

// Default implementation
class _MemoryStoreAdapter extends Adapter { ... }

// Future: RedisAdapter, MongoAdapter, etc.
```

### 4. Observer Pattern

Event system foundation:

```dart
server.on('connection', (socket) { ... });
socket.on('message', (data) { ... });
```

### 5. Strategy Pattern

Transport selection and fallback:

```dart
final transports = [
  WebSocketTransport(),
  PollingTransport(),
  JSONPTransport(),
];
```

---

## Extension Points

### Custom Adapters

Implement `Adapter` interface for distributed setups:

```dart
class RedisAdapter extends Adapter {
  @override
  void broadcast(Map packet, Map? opts) {
    redis.publish(channel, packet);
  }
}

server.adapter = 'redis';
Adapter.register('redis', (nsp) => RedisAdapter(nsp));
```

### Custom Transports

Extend `Transport` for new protocols:

```dart
class CustomTransport extends Transport {
  @override
  void send(List<Map> packets) { ... }
}
```

### Middleware

Add custom authentication, logging, rate limiting:

```dart
namespace.use((socket, next) {
  if (isAuthenticated(socket)) {
    next(null);
  } else {
    next('Authentication required');
  }
});
```

---

## Performance Considerations

### Memory Efficiency

- **Value Objects**: Immutable, can be cached/reused
- **Sealed Classes**: Optimized pattern matching
- **Event Handlers**: Lazy initialization of maps

### Type Safety Benefits

- **Compile-time checks**: Catch errors early
- **No runtime casts**: Faster execution
- **Better tree-shaking**: Unused code eliminated

### Scalability

- **Adapter pattern**: Enables horizontal scaling with Redis
- **Namespace isolation**: Prevents cross-talk
- **Room-based broadcasting**: Efficient message routing

---

## Future Architecture Plans

### Planned Improvements

1. **Distributed Adapters**: Redis, MongoDB support
2. **Binary Protocol**: More efficient encoding
3. **Streaming**: Large file transfer support
4. **State Management**: Persistent session state
5. **Metrics**: Built-in performance monitoring

### API Evolution

Following **deprecation policy**:

```
v2.x: Dual API (current)
v3.x: Deprecate legacy API
v4.x: Remove legacy API (breaking)
```

---

## Conclusion

socket_io's architecture balances:

✅ **Modern Dart**: Leverages Dart 3.0+ features  
✅ **Type Safety**: Value objects and sealed classes  
✅ **Backward Compatibility**: Smooth migration path  
✅ **Extensibility**: Adapters, middleware, custom transports  
✅ **Performance**: Efficient event routing and transport selection  
✅ **Maintainability**: Clear separation of concerns, comprehensive tests

The architecture supports both immediate production use and long-term evolution.

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-11  
**Maintainers:** socket_io team
