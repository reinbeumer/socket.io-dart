/// packet_id_vo.dart
///
/// Value object for packet ID with validation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library packet_id_vo;

/// Value object representing a validated packet ID.
///
/// Packet IDs are typically numeric identifiers for acknowledgments.
class PacketId {
  final String value;

  const PacketId._(this.value);

  /// Creates a PacketId from a string with validation.
  ///
  /// Throws [ArgumentError] if the ID is empty or invalid.
  factory PacketId(final String id) {
    if (id.isEmpty) {
      throw ArgumentError('Packet ID cannot be empty');
    }
    return PacketId._(id);
  }

  /// Creates a PacketId from an integer.
  factory PacketId.fromInt(final int id) {
    if (id < 0) {
      throw ArgumentError('Packet ID cannot be negative');
    }
    return PacketId._(id.toString());
  }

  /// Creates a PacketId without validation (use with caution).
  const PacketId.unchecked(this.value);

  /// Converts to integer if possible.
  int? toInt() => int.tryParse(value);

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is PacketId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
