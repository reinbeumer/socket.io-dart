// Node.js client for Socket.IO server
// Install: npm i socket.io-client
const io = require('socket.io-client');

// Allow overrides via env for easier debugging
const HOST = process.env.HOST || '127.0.0.1'; // prefer explicit IPv4 to avoid IPv6 binding issues
const PORT = Number(process.env.PORT || 3005);
const PATH = process.env.SOCKET_IO_PATH || '/socket.io';
// Comma-separated transports in env, default to polling first for maximum compatibility
const TRANSPORTS = (process.env.TRANSPORTS || 'polling,websocket')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

console.log('Starting Socket.IO client...');
console.log(`Target: http://${HOST}:${PORT}${PATH}`);
console.log('Transports:', TRANSPORTS);

const socket = io(`http://${HOST}:${PORT}`, {
  path: PATH,
  transports: TRANSPORTS,
  reconnection: false,
  forceNew: true,
  timeout: 5000,
});

// Helpful manager-level event logging
socket.io.on('error', (err) => console.log('manager error:', err && err.message || err));
socket.io.on('reconnect_attempt', (attempt) => console.log('manager reconnect_attempt:', attempt));
socket.io.on('reconnect_error', (err) => console.log('manager reconnect_error:', err && err.message || err));
socket.io.on('reconnect_failed', () => console.log('manager reconnect_failed'));

socket.on('connect', () => {
  console.log('✓ Connected to server!');
  console.log('  Socket ID:', socket.id);
  console.log('  Transport:', socket.io.engine.transport.name);
  // Send a message to the server
  socket.emit('message', 'Hello from Node.js client!');
});

socket.on('connect_error', (error) => {
  console.log('✗ Connect error:', error && error.message || error);
  console.log('  Hints:');
  console.log(`  - Is the server listening on http://${HOST}:${PORT}${PATH}?`);
  console.log('  - Try forcing polling only: TRANSPORTS=polling node example_client.js');
  console.log('  - Try IPv4: HOST=127.0.0.1 (instead of localhost)');
  console.log('  - If you changed the server path, set SOCKET_IO_PATH to match.');
});

socket.on('error', (error) => {
  console.log('✗ Error:', error);
});

// Useful heartbeat events
socket.on('ping', () => console.log('ping'));
socket.on('pong', (latency) => console.log('pong', latency));

socket.on('response', (data) => {
  console.log('✓ Server response:', data);
});

socket.on('disconnect', (reason) => {
  console.log('✗ Disconnected from server. Reason:', reason);
});

// Keep the process running a bit longer to allow observation
const LIFETIME_MS = Number(process.env.LIFETIME_MS || 5000);
setTimeout(() => {
  console.log('Closing connection...');
  socket.close();
  process.exit(0);
}, LIFETIME_MS);
