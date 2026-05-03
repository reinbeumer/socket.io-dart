/// common_types.dart
///
/// Common type aliases used across the Socket.IO library.
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library common_types;

/// General JSON-like map used within internal processing.
///
/// This is used for decoded packet data and other internal JSON structures.
typedef JsonMap = Map<String, dynamic>;

/// HTTP headers map used internally in transports before assigning to HttpHeaders.
///
/// Values may be String, int, or Iterable<String> depending on the header type.
/// This is primarily used in polling transport for constructing response headers.
typedef Headers = Map<String, Object>;
