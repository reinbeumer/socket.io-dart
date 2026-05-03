/// adapter_broadcast_models.dart
///
/// Models for adapter broadcast operations
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library adapter_broadcast_models;

import '../models/socket_flags_models.dart';
import '../value_objects/connection_id_vo.dart';
import '../value_objects/room_name_vo.dart';

/// Options for broadcasting packets to multiple clients.
///
/// Provides type-safe configuration for broadcast operations including
/// room targeting, exclusions, and transmission flags.
class BroadcastOptions {
  /// List of rooms to broadcast to. Empty list means broadcast to all.
  final List<RoomName> rooms;

  /// List of socket IDs to exclude from broadcast.
  final List<ConnectionId> except;

  /// Flags controlling transmission behavior (volatile, compress, etc.).
  final SocketFlags flags;

  /// Creates broadcast options.
  ///
  /// Example:
  /// ```dart
  /// final options = BroadcastOptions(
  ///   rooms: [RoomName('room1'), RoomName('room2')],
  ///   except: [ConnectionId('socket123')],
  ///   flags: SocketFlags(volatile: true),
  /// );
  /// ```
  const BroadcastOptions({
    this.rooms = const <RoomName>[],
    this.except = const <ConnectionId>[],
    this.flags = const SocketFlags(),
  });

  /// Creates broadcast options from legacy Map format.
  ///
  /// Provides backward compatibility with existing code.
  factory BroadcastOptions.fromMap(final Map<String, dynamic> map) {
    final List<dynamic>? roomsList = map['rooms'] as List<dynamic>?;
    final List<dynamic>? exceptList = map['except'] as List<dynamic>?;
    final Map<String, dynamic>? flagsMap = map['flags'] as Map<String, dynamic>?;

    // Convert Map<String, dynamic> to Map<String, bool> for SocketFlags
    Map<String, bool>? flagsBoolMap;
    if (flagsMap != null) {
      flagsBoolMap = <String, bool>{};
      for (final MapEntry<String, dynamic> entry in flagsMap.entries) {
        flagsBoolMap[entry.key] = entry.value as bool? ?? false;
      }
    }

    return BroadcastOptions(
      rooms: roomsList?.map((final dynamic r) => RoomName(r.toString())).toList() ?? const <RoomName>[],
      except: exceptList?.map((final dynamic e) => ConnectionId(e.toString())).toList() ?? const <ConnectionId>[],
      flags: flagsBoolMap != null ? SocketFlags.fromMap(flagsBoolMap) : const SocketFlags(),
    );
  }

  /// Converts to legacy Map format for backward compatibility.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'rooms': rooms.map((final RoomName r) => r.value).toList(),
        'except': except.map((final ConnectionId e) => e.value).toList(),
        'flags': flags.toMap(),
      };

  /// Creates a copy with modified fields.
  BroadcastOptions copyWith({
    final List<RoomName>? rooms,
    final List<ConnectionId>? except,
    final SocketFlags? flags,
  }) =>
      BroadcastOptions(
        rooms: rooms ?? this.rooms,
        except: except ?? this.except,
        flags: flags ?? this.flags,
      );

  /// Adds a room to the broadcast target list.
  BroadcastOptions addRoom(final RoomName room) => copyWith(rooms: <RoomName>[...rooms, room]);

  /// Adds multiple rooms to the broadcast target list.
  BroadcastOptions addRooms(final List<RoomName> newRooms) => copyWith(rooms: <RoomName>[...rooms, ...newRooms]);

  /// Excludes a socket ID from the broadcast.
  BroadcastOptions excludeSocket(final ConnectionId socketId) => copyWith(except: <ConnectionId>[...except, socketId]);

  /// Excludes multiple socket IDs from the broadcast.
  BroadcastOptions excludeSockets(final List<ConnectionId> socketIds) =>
      copyWith(except: <ConnectionId>[...except, ...socketIds]);

  /// Sets transmission flags.
  BroadcastOptions withFlags(final SocketFlags newFlags) => copyWith(flags: newFlags);

  /// Checks if broadcasting to specific rooms.
  bool get hasRoomFilter => rooms.isNotEmpty;

  /// Checks if any sockets are excluded.
  bool get hasExclusions => except.isNotEmpty;

  /// Checks if socket ID is excluded.
  bool isExcluded(final ConnectionId socketId) => except.contains(socketId);

  /// Checks if broadcasting to all rooms.
  bool get broadcastToAll => rooms.isEmpty;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BroadcastOptions &&
          runtimeType == other.runtimeType &&
          _listEquals(rooms, other.rooms) &&
          _listEquals(except, other.except) &&
          flags == other.flags;

  static bool _listEquals<T>(final List<T> a, final List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(rooms), Object.hashAll(except), flags);

  @override
  String toString() => 'BroadcastOptions(rooms: $rooms, except: $except, flags: $flags)';
}

/// Filter criteria for selecting rooms.
///
/// Provides type-safe room filtering operations.
class RoomFilter {
  /// Specific rooms to include in the filter.
  final List<RoomName> includeRooms;

  /// Specific rooms to exclude from the filter.
  final List<RoomName> excludeRooms;

  /// Pattern to match room names (if any).
  final String? namePattern;

  /// Creates a room filter.
  ///
  /// Example:
  /// ```dart
  /// final filter = RoomFilter(
  ///   includeRooms: [RoomName('game1'), RoomName('game2')],
  ///   excludeRooms: [RoomName('private')],
  /// );
  /// ```
  const RoomFilter({
    this.includeRooms = const <RoomName>[],
    this.excludeRooms = const <RoomName>[],
    this.namePattern,
  });

  /// Creates a filter that includes specific rooms.
  factory RoomFilter.include(final List<RoomName> rooms) => RoomFilter(includeRooms: rooms);

  /// Creates a filter that excludes specific rooms.
  factory RoomFilter.exclude(final List<RoomName> rooms) => RoomFilter(excludeRooms: rooms);

  /// Creates a filter based on a name pattern.
  factory RoomFilter.pattern(final String pattern) => RoomFilter(namePattern: pattern);

  /// Checks if a room matches this filter.
  bool matches(final RoomName room) {
    // Check exclusions first
    if (excludeRooms.contains(room)) {
      return false;
    }

    // If there are inclusions, room must be in the list
    if (includeRooms.isNotEmpty) {
      if (!includeRooms.contains(room)) {
        return false;
      }
    }

    // Check name pattern if specified
    if (namePattern != null) {
      final RegExp regex = RegExp(namePattern!);
      if (!regex.hasMatch(room.value)) {
        return false;
      }
    }

    return true;
  }

  /// Filters a list of rooms according to this filter.
  List<RoomName> filter(final List<RoomName> rooms) => rooms.where(matches).toList();

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RoomFilter &&
          runtimeType == other.runtimeType &&
          _listEquals(includeRooms, other.includeRooms) &&
          _listEquals(excludeRooms, other.excludeRooms) &&
          namePattern == other.namePattern;

  static bool _listEquals<T>(final List<T> a, final List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(includeRooms), Object.hashAll(excludeRooms), namePattern);

  @override
  String toString() => 'RoomFilter(include: $includeRooms, exclude: $excludeRooms, pattern: $namePattern)';
}
