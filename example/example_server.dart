import 'package:socket_io/socket_io.dart';

void main() async {
  // Use default options
  final Server io = Server();

  // Default namespace
  io.onConnection((final Socket socket) {
    print('Client connected: ${socket.id}');

    socket.on('message', (final SocketIOEventData data) {
      print('Received: $data');
      socket.emit('response', 'Message received');
    });

    socket.on('msg', (final SocketIOEventData data) {
      print('Received msg: $data');
      socket.emit('fromServer', 'Message received: $data');
    });

    socket.on('disconnect', (final SocketIOEventData data) {
      print('Client disconnected: ${socket.id}');
    });
  });

  // Custom namespace '/some'
  final Namespace someNamespace = io.of('/some');
  someNamespace.onConnection((final Socket socket) {
    print('Client connected to /some: ${socket.id}');

    socket.on('msg', (final SocketIOEventData data) {
      print('Received msg in /some: $data');
      socket.emit('fromServer', 'Message received in /some: $data');
    });

    socket.on('disconnect', (final SocketIOEventData data) {
      print('Client disconnected from /some: ${socket.id}');
    });
  });

  await io.listen(3005);
  print('Server listening on port 3005');
}
