/// socket_flags_models.dart
///
/// Type-safe models for Socket.IO socket flags to replace Map<String, bool>
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library socket_flags_models;

/// Socket flags control various aspects of how messages are sent
///
/// This model replaces the generic Map<String, bool> with a type-safe,
/// immutable structure that makes flag management explicit and prevents typos.
class SocketFlags {
  /// Whether to use JSON serialization
  final bool json;

  /// Whether the message is volatile (may be dropped if client is not ready)
  final bool volatile;

  /// Whether to broadcast to all clients
  final bool broadcast;

  /// Whether to compress the message
  final bool compress;

  /// Whether the packet is pre-encoded
  final bool preEncoded;

  /// Creates socket flags with specified values
  const SocketFlags({
    this.json = false,
    this.volatile = false,
    this.broadcast = false,
    this.compress = false,
    this.preEncoded = false,
  });

  /// Creates default flags (all false)
  const SocketFlags.none()
      : json = false,
        volatile = false,
        broadcast = false,
        compress = false,
        preEncoded = false;

  /// Creates flags for JSON serialization
  const SocketFlags.json()
      : json = true,
        volatile = false,
        broadcast = false,
        compress = false,
        preEncoded = false;

  /// Creates flags for volatile messages
  const SocketFlags.volatile()
      : json = false,
        volatile = true,
        broadcast = false,
        compress = false,
        preEncoded = false;

  /// Creates flags for broadcast messages
  const SocketFlags.broadcast()
      : json = false,
        volatile = false,
        broadcast = true,
        compress = false,
        preEncoded = false;

  /// Creates flags for compressed messages
  const SocketFlags.compress()
      : json = false,
        volatile = false,
        broadcast = false,
        compress = true,
        preEncoded = false;

  /// Creates flags for pre-encoded packets
  const SocketFlags.preEncoded()
      : json = false,
        volatile = false,
        broadcast = false,
        compress = false,
        preEncoded = true;

  /// Creates from a legacy map (for backward compatibility)
  factory SocketFlags.fromMap(final Map<String, bool> map) => SocketFlags(
        json: map['json'] ?? false,
        volatile: map['volatile'] ?? false,
        broadcast: map['broadcast'] ?? false,
        compress: map['compress'] ?? false,
        preEncoded: map['preEncoded'] ?? false,
      );

  /// Converts to legacy map format (for backward compatibility)
  Map<String, bool> toMap() => <String, bool>{
        if (json) 'json': true,
        if (volatile) 'volatile': true,
        if (broadcast) 'broadcast': true,
        if (compress) 'compress': true,
        if (preEncoded) 'preEncoded': true,
      };

  /// Creates a copy with modified flags
  SocketFlags copyWith({
    final bool? json,
    final bool? volatile,
    final bool? broadcast,
    final bool? compress,
    final bool? preEncoded,
  }) =>
      SocketFlags(
        json: json ?? this.json,
        volatile: volatile ?? this.volatile,
        broadcast: broadcast ?? this.broadcast,
        compress: compress ?? this.compress,
        preEncoded: preEncoded ?? this.preEncoded,
      );

  /// Checks if any flag is set
  bool get hasAnyFlag => json || volatile || broadcast || compress || preEncoded;

  /// Checks if no flags are set
  bool get hasNoFlags => !hasAnyFlag;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SocketFlags &&
          json == other.json &&
          volatile == other.volatile &&
          broadcast == other.broadcast &&
          compress == other.compress &&
          preEncoded == other.preEncoded;

  @override
  int get hashCode => Object.hash(json, volatile, broadcast, compress, preEncoded);

  @override
  String toString() {
    final List<String> flags = <String>[];
    if (json) flags.add('json');
    if (volatile) flags.add('volatile');
    if (broadcast) flags.add('broadcast');
    if (compress) flags.add('compress');
    if (preEncoded) flags.add('preEncoded');
    return 'SocketFlags(${flags.isEmpty ? 'none' : flags.join(', ')})';
  }
}

/// Extension to convert Map<String, bool> to SocketFlags
extension MapToSocketFlags on Map<String, bool> {
  /// Converts this map to SocketFlags
  SocketFlags toSocketFlags() => SocketFlags.fromMap(this);
}

/// Extension to convert Map<String, bool>? to SocketFlags?
extension NullableMapToSocketFlags on Map<String, bool>? {
  /// Converts this nullable map to SocketFlags, returning SocketFlags.none() if null
  SocketFlags toSocketFlagsOrNone() {
    final Map<String, bool>? self = this;
    return self == null ? const SocketFlags.none() : SocketFlags.fromMap(self);
  }

  /// Converts this nullable map to nullable SocketFlags
  SocketFlags? toSocketFlagsOrNull() {
    final Map<String, bool>? self = this;
    return self == null ? null : SocketFlags.fromMap(self);
  }
}
