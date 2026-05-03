/// socket_io - A modern, type-safe Socket.IO server implementation for Dart.
///
/// This library provides a Dart implementation of the Socket.IO protocol for
/// real-time bidirectional event-based communication.
///
/// ## Features
///
/// * **Real-time Communication**: WebSocket with automatic fallback to HTTP long-polling
/// * **Type Safety**: Modern Dart 3.0+ with value objects and sealed classes
/// * **Namespaces**: Organize connections into separate communication channels
/// * **Rooms**: Group sockets for targeted message broadcasting
/// * **Binary Support**: Send and receive binary data efficiently
/// * **Backward Compatible**: Dual API supports both legacy and modern patterns
///
/// ## Quick Start
///
/// ### Server Setup
///
/// ```dart
/// import 'package:socket_io/socket_io.dart';
///
/// void main() {
///   final io = Server();
///
///   io.on('connection', (socket) {
///     print('Client connected: ${socket.id}');
///
///     socket.on('message', (data) {
///       print('Received: $data');
///       socket.emit('response', ['Message received']);
///     });
///
///     socket.on('disconnect', (reason) {
///       print('Client disconnected: $reason');
///     });
///   });
///
///   io.listen(3000);
///   print('Socket.IO server running on port 3000');
/// }
/// ```
///
/// ### Namespaces
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
///   socket.join('general');
///   chat.to('general').emit('user-joined', [socket.id]);
/// });
/// ```
///
/// ### Rooms
///
/// ```dart
/// io.on('connection', (socket) {
///   // Join room
///   socket.join('room1');
///
///   // Emit to room
///   io.to('room1').emit('announcement', ['Welcome!']);
///
///   // Broadcast to room except sender
///   socket.broadcast.to('room1').emit('message', ['User joined']);
///
///   // Leave room
///   socket.leave('room1');
/// });
/// ```
///
/// ## Type-Safe API
///
/// This library provides a modern type-safe API using value objects and
/// domain models:
///
/// ```dart
/// // Value objects for type safety
/// final roomName = RoomName('chatRoom');
/// final eventName = EventName('customEvent');
/// final timeout = TimeoutDuration.seconds(30);
///
/// // Typed handshake data
/// final handshake = socket.handshakeData;
/// print('Connected from: ${handshake?.address}');
/// print('Secure: ${handshake?.secure}');
///
/// // Typed socket data
/// socket.socketData.set('userId', 123);
/// final userId = socket.socketData.getInt('userId');
/// ```
///
/// ## Main Classes
///
/// * [Server] - The main Socket.IO server
/// * [Namespace] - Separate communication channels
/// * [Socket] - Individual client connections
///
/// ## Transport Classes
///
/// * [WebSocketTransport] - Full-duplex WebSocket transport
/// * [PollingTransport] - HTTP long-polling fallback
/// * [JSONPTransport] - Legacy JSONP support
///
/// ## See Also
///
/// * [socket_io_common](https://pub.dev/packages/socket_io_common) - Shared components
/// * [socket_io_client](https://pub.dev/packages/socket_io_client) - Dart client
/// * [Socket.IO Documentation](https://socket.io/docs/) - Official protocol docs
library socket_io;

export 'package:socket_io_common/src/engine/parser/parser.dart' show PacketParser;
export 'package:socket_io_common/src/parser/parser.dart'
    show ACK, BINARY_ACK, BINARY_EVENT, CONNECT, CONNECT_ERROR, DISCONNECT, Decoder, EVENT, Encoder;

export 'src/client.dart';
export 'src/engine/transport/jsonp_transport.dart' show JSONPTransport;
export 'src/engine/transport/polling_transport.dart' show PollingTransport;
export 'src/engine/transport/transports.dart' show MessageHandler, Transport;
export 'src/engine/transport/websocket_transport.dart' show WebSocketTransport;
export 'src/models/packet_models.dart';
export 'src/models/server_options_models.dart'
    show
        AllowRequestCallback,
        AttachmentOptionsModel,
        CookieConfig,
        CookiePathConfig,
        DisabledCookie,
        DisabledCookiePath,
        EnabledCookie,
        EnabledCookiePath,
        HttpCompressionConfig,
        PerMessageDeflateConfig,
        ServerOptionsModel;
export 'src/namespace.dart' show Namespace;
export 'src/server.dart' show Server;
export 'src/socket.dart' show Socket;
export 'src/util/event_emitter.dart' show EventHandler, SocketIOEventData;
export 'src/value_objects/event_name_vo.dart';
export 'src/value_objects/timeout_duration_vo.dart';
export 'src/value_objects/transport_name_vo.dart';
export 'src/value_objects/url_path_vo.dart';
