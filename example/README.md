# Examples

This folder contains a small curated set of runnable examples.

## Kept examples

- `example_server.dart` - Socket.IO server (port `3005`)
- `example_client.js` - Node.js client example
- `example_client.dart` - short note pointing to supported client examples
- `example_client.html` - browser client with connect/send UI and live logs
- `polling_smoke.dart` - raw Engine.IO polling smoke check

## Quick run

Start the server first:

```zsh
dart run example/example_server.dart
```

Run the polling smoke check:

```zsh
dart run example/polling_smoke.dart
```

Run the Node.js client:

```zsh
cd example
npm install
node example_client.js
```

Open the browser client:

```zsh
open example/example_client.html
```
