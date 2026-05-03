# Changelog

All notable changes to this fork are documented here.
This fork tracks upstream [`rikulo/socket.io-dart`](https://github.com/rikulo/socket.io-dart)
and adds the fixes listed below.  Once these are accepted upstream the
`dependency_override` in consuming projects can be removed.

---

## 2.0.1 – 2026-05-03

### Fixed

- **Polling transport – packet splitting** (`lib/src/engine/transport/polling_transport.dart`)  
  `onData()` previously called `PacketParser.decodePayload()` which cannot
  parse Engine.IO v4 / Socket.IO v3+ payloads.  Replaced with a custom
  `_splitPackets()` splitter that locates packet boundaries on `]`, `}` or
  `"` followed by a digit, then decodes each packet individually via
  `PacketParser.decodePacket()`.  This makes polling fully equivalent to the
  WebSocket transport for all current Socket.IO clients (JS, browser, Dart).
- **Polling transport – connection close race** (`doWrite / respond`)  
  `respond()` was synchronous and used `unawaited(connect!.close())`, causing
  premature or failed connection closes that produced *xhr poll error* on
  clients.  `respond` is now `async` and `await`s `connect!.close()`.
- **Polling transport – CORS headers**  
  Added `Access-Control-Allow-Origin`, `Access-Control-Allow-Credentials`,
  `Access-Control-Allow-Methods`, and cache-control headers to every polling
  response so browser and cross-origin Dart clients do not get blocked.
- **Namespace – typed connection handler**  
  `onConnection()` now casts the raw `dynamic` listener argument to `Socket`
  before invoking the typed `EventHandler<Socket>` callback.

### Added

- `example/polling_smoke.dart` – raw Engine.IO v4 polling smoke test that
  can be run against a live server to verify the polling fix end-to-end.
- `--with-polling-smoke` flag in `tool/check.sh`.

---

## 2.0.0 – 2025-10-11

### Changed (breaking – Dart 3 migration)

- Minimum SDK raised to `>=3.0.0 <4.0.0`.
- Dart 3 modernisation: sealed classes, records, exhaustive switches, and
  improved null-safety throughout.
- Package renamed from `tp_socket_io` to `socket_io`; all import paths
  updated (`package:socket_io/socket_io.dart`).

### Added

- **Typed API** – value objects (`ConnectionId`, `RoomName`, `EventName`,
  `NamespaceName`, `PortNumber`, …) and sealed domain models
  (`SocketIOPacket`, `SocketIOError`, `TransportData`, …) alongside the
  legacy untyped API for gradual migration.
- **Expanded test suite** – 773 tests across 34 files covering every value
  object, model, extension, and error type.
- `doc/ARCHITECTURE.md`, `doc/TYPE_SAFE_EXAMPLES.md`,
  `doc/TYPE_SAFETY_MIGRATION_GUIDE.md`, `doc/QUICK_REFERENCE.md`.

---

## 1.0.1 – upstream baseline

Upstream release from [`rikulo/socket.io-dart`](https://github.com/rikulo/socket.io-dart).
See [upstream CHANGELOG](https://github.com/rikulo/socket.io-dart/blob/master/CHANGELOG.md)
for history prior to this fork.
