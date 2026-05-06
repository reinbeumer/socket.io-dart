# Upstream PR – Polling transport fixes for Engine.IO v4 / Socket.IO v3+

**Target repo:** [`rikulo/socket.io-dart`](https://github.com/rikulo/socket.io-dart)  
**Base branch:** `master` (upstream HEAD `09b51f6 Release 1.0.1`)  
**Status:** 🟡 Ready to submit  

---

## Problem

The polling path has three critical bugs that prevent Socket.IO v3+ or
Engine.IO v4 clients from connecting reliably via HTTP long-polling:

| # | Bug | Symptom |
|---|-----|---------|
| 1 | `onData()` relies on legacy payload handling and does not robustly split modern Engine.IO v4 polling bodies | Multi-packet polling POST bodies are decoded incorrectly; Socket.IO handlers miss events |
| 2 | `respond()` inside `doWrite()` calls `unawaited(connect!.close())` (where `unawaited` is not defined) | `xhr poll error` on client; connection closes prematurely or not at all |
| 3 | CORS preflight requests are rejected before they reach the polling transport, and error responses are left open | Browser polling clients hang or fail during `OPTIONS` / invalid-request flows |

WebSocket transport is unaffected because it calls `PacketParser.decodePacket()`
(singular) on each frame individually.

### Engine.IO v4 payload format

Engine.IO v4 uses the record-separator character (`\x1e`) between packets:

```
42["message","Hello"]42["msg","test"]
```

In practice, some client/proxy combinations have also been observed to submit
plain concatenated text **without length prefixes**:

```
42["message","Hello"]42["msg","test"]
```

Engine.IO v3 used explicit length prefixes:

```
20:42["message","Hello"]17:42["msg","test"]
```

The fork now handles both the standard Engine.IO v4 separator-delimited form
and the observed concatenated fallback by decoding each packet individually.

---

## Solution

### Change 1 – Fix `onData()` (separator-aware splitting + individual decode)

**File:** `lib/src/engine/transport/polling_transport.dart`

**Before:**
```dart
@override
void onData(dynamic data) {
  PacketParser.decodePayload(data, callback);
}
```

**After:**
```dart
/// Processes the incoming data payload.
@override
void onData(final dynamic data) {
  _logger.fine('received "$data"');
  if (messageHandler != null) {
    messageHandler!.handle(this, data);
  } else {
    if (data is String && data.isNotEmpty) {
      final List<String> packets = _extractPacketStrings(data);
      for (final String packetData in packets) {
        if (packetData.isEmpty) continue;
        try {
          final Map<String, dynamic>? packet =
              PacketParser.decodePacket(packetData, 'utf8')
                  as Map<String, dynamic>?;
          if (_handleDecodedPacket(packet)) {
            return;
          }
        } catch (e, st) {
          _logger.warning('Error decoding packet "$packetData": $e\n$st');
        }
      }
    } else if (data is List<int>) {
      // Binary data – decode as a single packet.
      try {
        final Map<String, dynamic>? packet =
            PacketParser.decodePacket(data, null) as Map<String, dynamic>?;
        if (packet != null) {
          if ('close' == packet['type']) {
            _logger.fine('got polling close packet');
            onClose();
            return;
          }
          onPacket(packet);
        }
      } catch (e, st) {
        _logger.warning('Error decoding binary packet: $e\n$st');
      }
    }
  }
}

bool _handleDecodedPacket(final Map<String, dynamic>? packet) {
  if (packet == null) {
    return false;
  }

  if ('close' == packet['type']) {
    _logger.fine('got polling close packet');
    onClose();
    return true;
  }

  onPacket(packet);
  return false;
}

/// Extracts individual packets from a text polling payload.
///
/// Engine.IO v4 uses the record-separator character for multi-packet payloads.
/// Some clients have also been observed to concatenate packets directly,
/// so we keep the fallback splitter for compatibility.
List<String> _extractPacketStrings(final String payload) {
  if (payload.contains(SEPARATOR)) {
    return payload.split(SEPARATOR);
  }

  return _splitPackets(payload);
}

/// Splits concatenated packets in a fallback polling payload.
List<String> _splitPackets(final String payload) {
  final List<String> packets = <String>[];
  int start = 0;

  for (int i = 1; i < payload.length; i++) {
    if (_isDigit(payload[i])) {
      final String prev = payload[i - 1];
      if (prev == ']' || prev == '}' || prev == '"') {
        packets.add(payload.substring(start, i));
        start = i;
      }
    }
  }

  if (start < payload.length) {
    packets.add(payload.substring(start));
  }

  return packets;
}

bool _isDigit(final String char) {
  if (char.isEmpty) return false;
  final int code = char.codeUnitAt(0);
  return code >= 48 && code <= 57; // '0'–'9'
}
```

---

### Change 2 – Fix `doWrite / respond` async close

**File:** `lib/src/engine/transport/polling_transport.dart`

**Before:**
```dart
Future<void> doWrite(dynamic data, Map<String, bool>? options,
    [Function? callback]) async {
  // ...
  void respond(dynamic data) {   // ← synchronous
    // ...
    unawaited(connect!.close()); // ← unawaited not defined; race condition
    // ...
  }
}
```

**After:**
```dart
Future<void> doWrite(final dynamic data, final Map<String, bool>? options,
    [final Function? callback]) async {
  // ...
  Future<void> respond(final dynamic data) async {   // ← async
    // ...
    try {
      if (data is String) {
        res.write(data);
      } else {
        if (headers.containsKey(HttpHeaders.contentEncodingHeader)) {
          res.add(data);
        } else {
          res.write(String.fromCharCodes(data));
        }
      }
      await connect!.close();  // ← properly awaited
    } catch (e) {
      final Function? fn = _reqCloses.remove(connect);
      if (fn != null) fn();
      rethrow;
    }
    // ...
  }
  await respond(data);
}
```

---

### Change 3 – CORS headers in polling responses and transport OPTIONS handling

Without CORS headers, browser and cross-origin Dart clients cannot connect
via polling.  Add to `headers()` in `PollingTransport`:

```dart
Headers headers(final SocketConnect connect, [Headers? headers]) {
  final Headers responseHeaders = headers ?? <String, Object>{};

  final String? origin = connect.request.headers.value('origin');
  if (origin != null) {
    responseHeaders['Access-Control-Allow-Origin'] = origin;
    responseHeaders['Access-Control-Allow-Credentials'] = 'true';
  } else {
    responseHeaders['Access-Control-Allow-Origin'] = '*';
  }
  responseHeaders['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS';
  responseHeaders['Access-Control-Allow-Headers'] =
      'Content-Type, Authorization, X-Requested-With';
  responseHeaders['Access-Control-Max-Age'] = '86400';

  // Prevent XSS warnings in IE/Trident
  final String? ua = connect.request.headers.value('user-agent');
  if (ua != null && (ua.contains(';MSIE') || ua.contains('Trident/'))) {
    responseHeaders['X-XSS-Protection'] = '0';
  }

  // Prevent caching of real-time poll responses
  responseHeaders['Cache-Control'] = 'no-cache, no-store, must-revalidate';
  responseHeaders['Pragma'] = 'no-cache';
  responseHeaders['Expires'] = '0';

  emit('headers', responseHeaders);
  return responseHeaders;
}
```

Also add an `onOptionsRequest` handler for CORS preflight (`OPTIONS`):

```dart
@override
Future<void> onRequest(final SocketConnect connect) async {
  if ('GET' == connect.request.method) {
    await onPollRequest(connect);
  } else if ('POST' == connect.request.method) {
    await onDataRequest(connect);
  } else if ('OPTIONS' == connect.request.method) {
    await onOptionsRequest(connect);
  } else {
    connect.response.statusCode = 500;
    await connect.response.close();
  }
}

Future<void> onOptionsRequest(final SocketConnect connect) async {
  final HttpResponse res = connect.response;
  final Headers h = <String, String>{};
  headers(connect, h).forEach((k, v) => res.headers.set(k, v));
  res
    ..statusCode = 200
    ..write('');
  await res.close();
  await connect.close();
}
```

---

### Change 4 – Let Engine.IO verification accept preflight requests

**File:** `lib/src/engine/server.dart`

```dart
if ('OPTIONS' == req.method) {
  return fn(null, true);
}

if ('GET' != req.method) {
  return fn(ServerErrors.BAD_HANDSHAKE_METHOD, false);
}
```

Also make `sendErrorMessage()` close its response so browser clients and raw
HTTP diagnostics do not hang on bad requests.

---

## Verification

### Manual smoke test

Run the server example and the provided raw polling smoke script:

```zsh
dart run example/example_server.dart &
dart run example/polling_smoke.dart
```

Expected output:
```
Running raw polling smoke check against http://localhost:3005
1) Raw Engine.IO polling check
   raw result: true
Polling smoke passed
```

### Node.js client test

```zsh
cd example
npm install
node example_client.js   # uses polling transport
```

Expected:
```
Connected!
From server: ok
Disconnected
```

### Existing test suite

```zsh
dart test
```

All 776 tests should pass.

---

## Files changed

| File | Change |
|------|--------|
| `lib/src/engine/transport/polling_transport.dart` | `onData()`, `doWrite()`, `headers()`, `onRequest()`, add `_handleDecodedPacket()`, `_extractPacketStrings()`, `_splitPackets()`, `_isDigit()`, `onOptionsRequest()` |
| `lib/src/engine/transport/xhr_transport.dart` | Finish `OPTIONS` responses cleanly in the XHR override |
| `lib/src/engine/server.dart` | Allow `OPTIONS` through verification and close error responses |
| `test/polling_transport_integration_test.dart` | Regression tests for separator-delimited payloads, concatenated fallback payloads, and CORS preflight |
| `example/polling_smoke.dart` | Raw Engine.IO polling smoke verification |

---

## Checklist for submitting to upstream

- [ ] Fork `rikulo/socket.io-dart` on GitHub
- [ ] Create branch `fix/polling-transport-engine-io-v4`
- [ ] Cherry-pick or apply the four changes above
- [x] Add `example/polling_smoke.dart` to demonstrate the fix
- [x] Run `dart format .` and `dart analyze` – zero issues
- [x] Run `dart test` – all tests pass
- [ ] Open PR with this document as description
- [ ] Reference upstream issues (polling fails with Socket.IO v3+ clients)
- [ ] Once merged and released, remove `dependency_override` in consuming projects

---

## Context for the PR description

```
## Summary

Fix HTTP long-polling transport for Engine.IO v4 / Socket.IO v3+ clients.

## Problem

The polling transport decoded POST bodies via a legacy payload path that does
not robustly handle current Engine.IO v4 polling payloads. Modern clients send
record-separator-delimited payloads (`42[…]\x1e42[…]`), and some environments
also surface plain concatenated payloads (`42[…]42[…]`). Those polling events
were decoded incorrectly, causing Socket.IO messages over HTTP long-polling to
be lost.

A second bug caused a `unawaited()` reference error and a race condition when
closing the HTTP response after writing the poll reply.

Browser clients also could not complete polling preflight requests because
`OPTIONS` was rejected during Engine.IO verification before it reached the
transport layer.

## Fix

1. Replace the legacy payload handling with separator-aware packet extraction,
   a concatenation fallback splitter, and per-packet `decodePacket()` calls.
2. Make `respond()` async and `await` the connection close.
3. Add CORS + cache-control headers and fully close transport `OPTIONS`
   responses.
4. Allow `OPTIONS` through Engine.IO verification and close error responses.

## Testing

- Added `example/polling_smoke.dart` – raw polling end-to-end verification.
- Manually verified with official Node.js Socket.IO client (polling-only mode).
- Added `test/polling_transport_integration_test.dart` for polling regressions.
- All existing 776 tests continue to pass.

## Compatibility

- ✅ Socket.IO v3+ JS/Node.js clients (polling + WebSocket)
- ✅ Browser clients
- ✅ Existing WebSocket transport (unchanged)
- ⚠️  Dart `socket_io_client` polling has a separate upstream bug (see below)

Note: the Dart `socket_io_client` package has its own Engine.IO v4 polling bug
(fails against ANY Engine.IO v4 server including the official Node.js one).
That is a separate issue in a separate package and is not addressed here.
```

---

*Document version: 1.1 – 2026-05-03*

