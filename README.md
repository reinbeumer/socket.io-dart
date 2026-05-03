# socket_io

[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.0.0-blue.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![Fork of rikulo/socket.io-dart](https://img.shields.io/badge/fork-rikulo%2Fsocket.io--dart-orange.svg)](https://github.com/rikulo/socket.io-dart)

> **This is a fork** of [`rikulo/socket.io-dart`](https://github.com/rikulo/socket.io-dart) with critical polling-transport fixes for Engine.IO v4 /
> Socket.IO v3+ clients that are not yet merged upstream.  Once upstream accepts these changes this
> package can be replaced with the official `socket_io` from pub.dev and the
> `dependency_override` can be removed.
>
> **Upstream PR tracking:** see [`doc/UPSTREAM_PR.md`](doc/UPSTREAM_PR.md).

A modern, type-safe Dart implementation of [Socket.IO](https://socket.io/) for real-time
bidirectional event-based communication.

Port of the JavaScript Node.js library [Socket.IO](https://github.com/socketio/socket.io) with
modern Dart 3.0+ features including sealed classes, value objects, and comprehensive type safety.

## Features

✨ **Modern & Type-Safe**
- Full Dart 3.0+ support with sealed classes and pattern matching
- Comprehensive type safety with value objects and domain models
- Dual API: backward-compatible legacy API + modern typed API

🔌 **Complete Socket.IO Implementation**
- Real-time bidirectional communication
- Multiple transport support (WebSocket, HTTP long-polling, JSONP)
- Namespace and room support for message isolation
- Acknowledgment callbacks
- Binary data support

🏗️ **Production Ready**
- 748+ passing tests with comprehensive coverage
- Zero analysis issues
- Extensive error handling with typed error models
- Full backward compatibility

## Installation

### Using this fork (recommended until upstream fix is merged)

Add a `dependency_override` in your project's `pubspec.yaml` to use this fork
from your local checkout or from GitHub:

```yaml
# pubspec.yaml of your consuming project
dependencies:
  socket_io: ^2.0.1

dependency_overrides:
  socket_io:
    git:
      url: https://github.com/reinbeumer/socket.io-dart.git
      ref: master
```

Or point directly to a local path during development:

```yaml
dependency_overrides:
  socket_io:
    path: /path/to/socket.io-dart
```

Then run:

```zsh
dart pub get
```

### Removing the override (once fix is upstream)

When the polling fix is accepted into [`rikulo/socket.io-dart`](https://github.com/rikulo/socket.io-dart)
and a new version is published to pub.dev, simply remove the `dependency_overrides` block and bump
the version constraint to require the fixed release.

## Quick Start

### Server Example

```dart
import 'package:socket_io/socket_io.dart';

void main() {
  // Create a Socket.IO server
  final io = Server();
  
  // Listen for client connections
  io.onConnection((socket) {
    print('Client connected: ${socket.id}');
    
    // Listen for messages from client
    socket.on('message', (data) {
      print('Received: $data');
      
      // Send acknowledgment back to client
      socket.emit('messageReceived', ['Message processed']);
    });
    
    // Handle disconnection
    socket.on('disconnect', (_) {
      print('Client disconnected: ${socket.id}');
    });
  });
  
  // Start listening on port 3000
  io.listen(3000);
  print('Socket.IO server running on port 3000');
}
```

### Client Example (JavaScript)

```javascript
const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('Connected to server');
  socket.emit('message', 'Hello from client!');
});

socket.on('messageReceived', (data) => {
  console.log('Server response:', data);
});

socket.on('disconnect', () => {
  console.log('Disconnected from server');
});
```

### Client Example (Dart)

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  final socket = IO.io('http://localhost:3000');
  
  socket.on('connect', (_) {
    print('Connected to server');
    socket.emit('message', 'Hello from Dart client!');
  });
  
  socket.on('messageReceived', (data) {
    print('Server response: $data');
  });
  
  socket.on('disconnect', (_) {
    print('Disconnected from server');
  });
}
```

## Core Concepts

### Namespaces

Namespaces allow you to create separate communication channels over a single connection:

```dart
final io = Server();

// Default namespace
io.onConnection((socket) {
  print('Client connected to default namespace');
});

// Custom namespace
final chatNamespace = io.of('/chat');
chatNamespace.on('connection', (socket) {
  print('Client connected to /chat namespace');
  
  socket.on('chatMessage', (data) {
    // Broadcast to all clients in this namespace
    chatNamespace.emit('newMessage', data);
  });
});

io.listen(3000);
```

### Rooms

Rooms are arbitrary channels that sockets can join and leave:

```dart
io.onConnection((socket) {
  // Join a room
  socket.join('room1');
  
  // Emit to all clients in a room
  io.to('room1').emit('announcement', ['Welcome to room1']);
  
  // Leave a room
  socket.leave('room1');
  
  // Broadcast to all except sender
  socket.broadcast.to('room1').emit('userJoined', [socket.id]);
});
```

### Acknowledgments

Request callbacks from the receiving side:

```dart
// Server side
socket.on('question', (data) {
  socket.emit('answer', ['The answer is 42'], ack: (response) {
    print('Client acknowledged: $response');
  });
});

// Client side
socket.emit('question', ['What is the meaning of life?'], ack: (answer) {
  print('Server answered: $answer');
});
```

## Modern Typed API

This library provides a modern, type-safe API alongside the legacy API for backward compatibility:

### Type-Safe Event Handling

```dart
import 'package:socket_io/socket_io.dart';

// Using typed models
socket.on('userLogin', (data) {
  final eventData = EventData.fromDynamic(data);
  if (eventData is MapEventData) {
    final username = eventData.value['username'];
    print('User logged in: $username');
  }
});

// Using typed query parameters
socket.queryParameters?.get('token'); // Type-safe access

// Using typed handshake data
final handshake = socket.handshakeData;
print('Connected from: ${handshake?.address}');
print('Secure connection: ${handshake?.secure}');
```

### Value Objects

The library uses value objects for type safety:

```dart
// Connection ID (validated non-empty string)
final connectionId = ConnectionId('socket-123');

// Room names (validated)
final room = RoomName('chatRoom');

// Event names (validated, no reserved names)
final event = EventName('customEvent');

// Namespace names (must start with /)
final namespace = NamespaceName('/admin');
```

### Sealed Classes for Pattern Matching

```dart
// Type-safe error handling
socket.on('error', (error) {
  if (error is SocketIOError) {
    switch (error) {
      case TransportErrorModel():
        print('Transport error: ${error.message}');
      case ConnectionErrorModel():
        print('Connection error: ${error.message}');
      case ValidationErrorModel():
        print('Validation error: ${error.message}');
    }
  }
});
```

## Advanced Features

### Middleware

Add middleware to process connections:

```dart
final io = Server();

// Namespace-level middleware
final adminNamespace = io.of('/admin');
adminNamespace.use((socket, next) {
  // Verify authentication token
  final token = socket.handshake?['auth']?['token'];
  if (token == 'secret') {
    next(null); // Allow connection
  } else {
    next('Authentication failed'); // Reject connection
  }
});

adminNamespace.onConnection((socket) {
  print('Authenticated admin connected');
});
```

### Custom Server Options

```dart
final io = Server(
  options: {
    'pingTimeout': 60000,
    'pingInterval': 25000,
    'transports': ['websocket', 'polling'],
    'path': '/socket.io',
  },
);
```

### Broadcasting

```dart
io.onConnection((socket) {
  // To all clients
  io.emit('broadcast', ['Message to everyone']);
  
  // To all clients except sender
  socket.broadcast.emit('broadcast', ['Message to others']);
  
  // To specific room
  io.to('room1').emit('roomMessage', ['Message to room1']);
  
  // To multiple rooms
  io.to('room1').to('room2').emit('multiRoom', ['Message']);
  
  // To room except sender
  socket.broadcast.to('room1').emit('announcement', ['User joined']);
});
```

### Binary Data

```dart
socket.on('image', (data) {
  if (data is List<int>) {
    // Handle binary data
    print('Received binary data of length: ${data.length}');
  }
});

// Send binary data
socket.emit('imageResponse', [imageBytes]);
```

## Transport Layers

The library supports multiple transport mechanisms:

1. **WebSocket** - Full-duplex communication channel
2. **HTTP Long-polling** - Fallback for environments without WebSocket support
3. **JSONP Polling** - Legacy support for older browsers

Transport selection is automatic based on client capabilities and can be configured:

```dart
final io = Server(
  options: {
    'transports': ['websocket', 'polling'], // Preferred order
  },
);
```

## Error Handling

Comprehensive typed error handling:

```dart
socket.on('error', (error) {
  if (error is SocketIOError) {
    print('Error type: ${error.type}');
    print('Message: ${error.message}');
    print('Code: ${error.code}');
    print('Context: ${error.context}');
  }
});

// Graceful error recovery
socket.on('connect_error', (error) {
  print('Connection failed, retrying...');
});
```

## Testing

Run tests:

```bash
dart test
```

Run tests with coverage:

```bash
dart test --coverage=coverage
dart pub global activate coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib
```

## API Documentation

For detailed API documentation, see:

- [TYPE_SAFE_EXAMPLES.md](doc/TYPE_SAFE_EXAMPLES.md) - Comprehensive examples of the typed API
- [TYPE_SAFETY_MIGRATION_GUIDE.md](doc/TYPE_SAFETY_MIGRATION_GUIDE.md) - Migration guide from legacy to typed API
- [QUICK_REFERENCE.md](doc/QUICK_REFERENCE.md) - Quick reference guide
- [UPGRADE_TO_V3.md](doc/archive/UPGRADE_TO_V3.md) - Upgrade guide for breaking changes

## Architecture

This library follows modern Dart architectural patterns:

- **Value Objects**: Type-safe primitives with validation (ConnectionId, RoomName, etc.)
- **Domain Models**: Rich models for business logic (SocketIOPacket, HandshakeData, etc.)
- **Sealed Classes**: Exhaustive pattern matching for errors and data types
- **Extension Methods**: Utility methods without cluttering core classes
- **Dual API**: Backward compatibility with modern type-safe alternatives

For detailed architecture documentation, see [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md).

## Compatibility

- **Dart SDK**: >= 3.0.0 < 4.0.0
- **Socket.IO Protocol**: Compatible with Socket.IO v2.x clients
- **Platforms**: VM, Web (with appropriate transport configuration)

## Migration from Legacy API

If you're using the legacy untyped API, you can gradually migrate to the typed API:

```dart
// Legacy (still supported)
socket.on('message', (data) {
  final Map<String, dynamic> map = data as Map<String, dynamic>;
  print(map['text']);
});

// Modern typed API
socket.on('message', (data) {
  final eventData = EventData.fromDynamic(data);
  if (eventData is MapEventData) {
    print(eventData.value['text']);
  }
});
```

See [TYPE_SAFETY_MIGRATION_GUIDE.md](doc/TYPE_SAFETY_MIGRATION_GUIDE.md) for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure all tests pass (`dart test`)
5. Ensure code is formatted (`dart format .`)
6. Ensure no analysis issues (`dart analyze`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

For detailed contribution guidelines, see [doc/CONTRIBUTING.md](doc/CONTRIBUTING.md).

## Examples

The [example](example/) directory is now intentionally small and focused:

- `example/example_server.dart` - server example (listens on port `3005`)
- `example/example_client.js` - Node.js client example
- `example/example_client.dart` - basic Dart client example
- `example/example_client.html` - browser client example with live logs
- `example/polling_smoke.dart` - raw Engine.IO polling smoke test

Quick run:

```zsh
dart run example/example_server.dart
dart run example/polling_smoke.dart
```

Optional full quality check including polling smoke:

```zsh
bash tool/check.sh --with-polling-smoke
```

Note: this package is server-only; client application examples are provided via
Node.js (`example/example_client.js`) and browser (`example/example_client.html`).

## Projects Using socket_io

- [Quire](https://quire.io) - A simple, collaborative, multi-level task management tool
- [KEIKAI](https://keikai.io/) - A web spreadsheet for Big Data

## Related Projects

- [socket.io-client-dart](https://github.com/rikulo/socket.io-client-dart) - Dart client for Socket.IO
- [socket_io_common](https://pub.dev/packages/socket_io_common) - Common components for Socket.IO

## License

Apache License 2.0 - see [LICENSE](LICENSE) file for details.

## Acknowledgments

This is a port of the JavaScript [Socket.IO](https://socket.io/) library. Special thanks to:

- The Socket.IO team for the original implementation
- All contributors who have helped improve this library
- The Dart team for the excellent language and tooling

## Support

- **Issues**: [GitHub Issues](https://github.com/reinbeumer/socket.io-dart/issues)
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Documentation**: Check the [doc](doc/) directory

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and migration notes.

---

Made with ❤️ by the Dart community
