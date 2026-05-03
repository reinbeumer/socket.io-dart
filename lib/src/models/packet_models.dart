/// packet_models.dart
///
/// Typed models for Socket.IO packets to replace dynamic map creation
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
library packet_models;

import 'package:socket_io_common/socket_io_common.dart';

import 'packet_data_models.dart';

/// Base sealed class for all Socket.IO packets
///
/// Using sealed class ensures exhaustive pattern matching and makes the set
/// of packet types closed - all subtypes are defined in this file.
sealed class SocketIOPacket {
  int get type;
  String? get namespace;
  Object? get data;
  String? get id;

  Map<String, dynamic> toMap();
}

/// Connect packet - sent when a client connects to a namespace
class ConnectPacket implements SocketIOPacket {
  @override
  final int type = CONNECT;

  @override
  final String? namespace;

  /// Typed connection data (preferred)
  final ConnectPacketData? typedData;

  /// Raw map data (deprecated, for backward compatibility)
  @Deprecated('Use typedData instead')
  final Map<String, dynamic>? rawData;

  @override
  final String? id;

  /// Creates a connect packet with typed data (preferred)
  ConnectPacket.typed({
    this.namespace,
    this.typedData,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  }) : rawData = null;

  /// Creates a connect packet with raw map data (deprecated)
  @Deprecated('Use ConnectPacket.typed() instead')
  ConnectPacket({
    this.namespace,
    final Map<String, dynamic>? data,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = data,
        typedData = data != null ? ConnectPacketData.fromJson(data) : null;

  @override
  // ignore: deprecated_member_use_from_same_package
  Object? get data => typedData ?? rawData;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (namespace != null) map['nsp'] = namespace;
    if (typedData != null) {
      map['data'] = typedData!.toJson();
      // ignore: deprecated_member_use_from_same_package
    } else if (rawData != null) {
      // ignore: deprecated_member_use_from_same_package
      map['data'] = rawData;
    }
    if (id != null) map['id'] = id;
    return map;
  }
}

/// Disconnect packet - sent when a client disconnects
class DisconnectPacket implements SocketIOPacket {
  @override
  final int type = DISCONNECT;

  @override
  final String? namespace;

  /// Typed disconnect data (preferred)
  final DisconnectPacketData? typedData;

  /// Raw data (deprecated, for backward compatibility)
  @Deprecated('Use typedData instead')
  final Object? rawData;

  @override
  final String? id;

  /// Creates a disconnect packet with typed data (preferred)
  DisconnectPacket.typed({
    this.namespace,
    this.typedData,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  }) : rawData = null;

  /// Creates a disconnect packet with raw data (deprecated)
  @Deprecated('Use DisconnectPacket.typed() instead')
  DisconnectPacket({
    this.namespace,
    final Object? data,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = data,
        typedData = data != null ? DisconnectPacketData.fromJson(data) : null;

  @override
  // ignore: deprecated_member_use_from_same_package
  Object? get data => typedData ?? rawData;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (namespace != null) map['nsp'] = namespace;
    if (typedData != null) {
      map['data'] = typedData!.toJson();
      // ignore: deprecated_member_use_from_same_package
    } else if (rawData != null) {
      // ignore: deprecated_member_use_from_same_package
      map['data'] = rawData;
    }
    if (id != null) map['id'] = id;
    return map;
  }
}

/// Event packet - sent when emitting an event
class EventPacket implements SocketIOPacket {
  @override
  final int type;

  @override
  final String? namespace;

  /// Typed event data (preferred)
  final EventPacketData? typedData;

  /// Raw list data (deprecated, for backward compatibility)
  @Deprecated('Use typedData instead')
  final List<dynamic>? rawData;

  @override
  final String? id;

  /// Creates an event packet with typed data (preferred)
  EventPacket.typed({
    required this.typedData,
    this.namespace,
    this.id,
    final bool binary = false,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = null,
        type = binary ? BINARY_EVENT : EVENT;

  /// Creates an event packet with raw list data (deprecated)
  @Deprecated('Use EventPacket.typed() instead')
  EventPacket({
    required final List<dynamic> data,
    this.namespace,
    this.id,
    final bool binary = false,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = data,
        typedData = EventPacketData.fromList(data),
        type = binary ? BINARY_EVENT : EVENT;

  @override
  // ignore: deprecated_member_use_from_same_package
  Object? get data => typedData?.toList() ?? rawData;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'type': type,
      // ignore: deprecated_member_use_from_same_package
      'data': typedData?.toList() ?? rawData,
    };
    if (namespace != null) map['nsp'] = namespace;
    if (id != null) map['id'] = id;
    return map;
  }
}

/// ACK packet - sent as a response to an event with callback
class AckPacket implements SocketIOPacket {
  @override
  final int type;

  @override
  final String? namespace;

  /// Typed ACK data (preferred)
  final AckPacketData? typedData;

  /// Raw list data (deprecated, for backward compatibility)
  @Deprecated('Use typedData instead')
  final List<dynamic>? rawData;

  @override
  final String id;

  /// Creates an ACK packet with typed data (preferred)
  AckPacket.typed({
    required this.id,
    required this.typedData,
    this.namespace,
    final bool binary = false,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = null,
        type = binary ? BINARY_ACK : ACK;

  /// Creates an ACK packet with raw list data (deprecated)
  @Deprecated('Use AckPacket.typed() instead')
  AckPacket({
    required this.id,
    required final List<dynamic> data,
    this.namespace,
    final bool binary = false,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = data,
        typedData = AckPacketData.fromList(data),
        type = binary ? BINARY_ACK : ACK;

  @override
  // ignore: deprecated_member_use_from_same_package
  Object? get data => typedData?.toList() ?? rawData;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'type': type,
      'id': id,
      // ignore: deprecated_member_use_from_same_package
      'data': typedData?.toList() ?? rawData,
    };
    if (namespace != null) map['nsp'] = namespace;
    return map;
  }
}

/// Connect Error packet - sent when connection to namespace fails
class ConnectErrorPacket implements SocketIOPacket {
  @override
  final int type = CONNECT_ERROR;

  @override
  final String? namespace;

  /// Typed error data (preferred)
  final ConnectErrorPacketData? typedData;

  /// Raw data (deprecated, for backward compatibility)
  @Deprecated('Use typedData instead')
  final Object? rawData;

  @override
  final String? id;

  /// Creates a connect error packet with typed data (preferred)
  ConnectErrorPacket.typed({
    required this.typedData,
    this.namespace,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  }) : rawData = null;

  /// Creates a connect error packet with raw data (deprecated)
  @Deprecated('Use ConnectErrorPacket.typed() instead')
  ConnectErrorPacket({
    required final Object? data,
    this.namespace,
    this.id,
    // ignore: deprecated_member_use_from_same_package
  })  : rawData = data,
        typedData = ConnectErrorPacketData.fromJson(data);

  @override
  // ignore: deprecated_member_use_from_same_package
  Object? get data => typedData?.toJson() ?? rawData;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'type': type,
      // ignore: deprecated_member_use_from_same_package
      'data': typedData?.toJson() ?? rawData,
    };
    if (namespace != null) map['nsp'] = namespace;
    if (id != null) map['id'] = id;
    return map;
  }
}

/// Factory class to create packets from maps (for parsing incoming data)
class PacketFactory {
  static SocketIOPacket fromMap(final Map<String, dynamic> data) {
    final int type = data['type'] as int;
    final String? namespace = data['nsp'] as String?;
    final String? id = data['id'] as String?;
    final dynamic packetData = data['data'];

    switch (type) {
      case CONNECT:
        return ConnectPacket.typed(
          namespace: namespace,
          typedData: packetData != null ? ConnectPacketData.fromJson(packetData as Map<String, dynamic>) : null,
          id: id,
        );

      case DISCONNECT:
        return DisconnectPacket.typed(
          namespace: namespace,
          typedData: packetData != null ? DisconnectPacketData.fromJson(packetData) : null,
          id: id,
        );

      case EVENT:
        return EventPacket.typed(
          typedData: EventPacketData.fromList(packetData as List<dynamic>),
          namespace: namespace,
          id: id,
          binary: false,
        );

      case BINARY_EVENT:
        return EventPacket.typed(
          typedData: EventPacketData.fromList(packetData as List<dynamic>),
          namespace: namespace,
          id: id,
          binary: true,
        );

      case ACK:
        return AckPacket.typed(
          id: id!,
          typedData: AckPacketData.fromList(packetData as List<dynamic>),
          namespace: namespace,
          binary: false,
        );

      case BINARY_ACK:
        return AckPacket.typed(
          id: id!,
          typedData: AckPacketData.fromList(packetData as List<dynamic>),
          namespace: namespace,
          binary: true,
        );

      case CONNECT_ERROR:
        return ConnectErrorPacket.typed(
          typedData: ConnectErrorPacketData.fromJson(packetData),
          namespace: namespace,
          id: id,
        );

      default:
        throw ArgumentError('Unknown packet type: $type');
    }
  }
}

/// Engine.IO packet models for transport layer
///
/// Using sealed class ensures exhaustive pattern matching and makes the set
/// of packet types closed - all subtypes are defined in this file.
sealed class EngineIOPacket {
  String get type;
  Object? get data; // Engine.IO data can be String or binary
  Map<String, bool>? get options; // only boolean flags are supported (e.g., compress)

  Map<String, dynamic> toMap();
}

/// Ping packet for Engine.IO
class PingPacket implements EngineIOPacket {
  @override
  final String type = 'ping';

  @override
  final Object? data;

  @override
  final Map<String, bool>? options;

  PingPacket({this.data, this.options});

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (data != null) map['data'] = data;
    if (options != null) map['options'] = options;
    return map;
  }
}

/// Pong packet for Engine.IO
class PongPacket implements EngineIOPacket {
  @override
  final String type = 'pong';

  @override
  final Object? data;

  @override
  final Map<String, bool>? options;

  PongPacket({this.data, this.options});

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (data != null) map['data'] = data;
    if (options != null) map['options'] = options;
    return map;
  }
}

/// Noop packet for Engine.IO
class NoopPacket implements EngineIOPacket {
  @override
  final String type = 'noop';

  @override
  final Object? data;

  @override
  final Map<String, bool>? options;

  NoopPacket({this.data, this.options});

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (data != null) map['data'] = data;
    if (options != null) map['options'] = options;
    return map;
  }
}

/// Close packet for Engine.IO
class ClosePacket implements EngineIOPacket {
  @override
  final String type = 'close';

  @override
  final Object? data;

  @override
  final Map<String, bool>? options;

  ClosePacket({this.data, this.options});

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{'type': type};
    if (data != null) map['data'] = data;
    if (options != null) map['options'] = options;
    return map;
  }
}

/// PacketOptions class for packet transmission options
class PacketOptions {
  final bool volatile;
  final bool compress;

  PacketOptions({
    this.volatile = false,
    this.compress = false,
  });

  Map<String, bool> toMap() => <String, bool>{
        'volatile': volatile,
        'compress': compress,
      };
}
