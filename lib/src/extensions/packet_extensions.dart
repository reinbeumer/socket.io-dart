/// packet_extensions.dart
///
/// Extension methods for Socket.IO packet operations
///
/// Provides type checking, validation, and convenience methods
/// for working with Socket.IO packets.
///
/// Copyright (C) 2024 Potix Corporation. All Rights Reserved.
library packet_extensions;

import 'package:socket_io_common/socket_io_common.dart';

import '../models/packet_models.dart';

/// Extension methods for SocketIOPacket
///
/// Provides convenient type checking and validation methods
extension PacketExtensions on SocketIOPacket {
  /// Check if this packet is a CONNECT packet
  bool get isConnect => type == CONNECT;

  /// Check if this packet is a DISCONNECT packet
  bool get isDisconnect => type == DISCONNECT;

  /// Check if this packet is an EVENT packet
  bool get isEvent => type == EVENT || type == BINARY_EVENT;

  /// Check if this packet is an ACK packet
  bool get isAck => type == ACK || type == BINARY_ACK;

  /// Check if this packet is a CONNECT_ERROR packet
  bool get isConnectError => type == CONNECT_ERROR;

  /// Check if this packet contains binary data
  bool get isBinary => type == BINARY_EVENT || type == BINARY_ACK;

  /// Check if this packet requires acknowledgment
  bool get requiresAck => id != null && (isEvent || isConnect);

  /// Check if this packet is an acknowledgment response
  bool get isAckResponse => isAck;

  /// Check if packet is for the default namespace
  bool get isDefaultNamespace => namespace == null || namespace == '/';

  /// Check if packet is for a custom namespace
  bool get isCustomNamespace => !isDefaultNamespace;

  /// Get the packet type as a human-readable string
  String get typeName {
    switch (type) {
      case CONNECT:
        return 'CONNECT';
      case DISCONNECT:
        return 'DISCONNECT';
      case EVENT:
        return 'EVENT';
      case ACK:
        return 'ACK';
      case CONNECT_ERROR:
        return 'CONNECT_ERROR';
      case BINARY_EVENT:
        return 'BINARY_EVENT';
      case BINARY_ACK:
        return 'BINARY_ACK';
      default:
        return 'UNKNOWN($type)';
    }
  }

  /// Check if packet has data payload
  bool get hasData => data != null;

  /// Check if packet has an ID
  bool get hasId => id != null;

  /// Get namespace or default
  String get effectiveNamespace => namespace ?? '/';

  /// Create a human-readable description of this packet
  String get description {
    final StringBuffer buffer = StringBuffer(typeName);

    if (isCustomNamespace) {
      buffer.write(' [${namespace!}]');
    }

    if (hasId) {
      buffer.write(' #$id');
    }

    if (hasData) {
      final String dataStr = data.toString();
      final String truncated = dataStr.length > 50 ? '${dataStr.substring(0, 47)}...' : dataStr;
      buffer.write(' data: $truncated');
    }

    return buffer.toString();
  }
}

/// Extension methods for ConnectPacket
extension ConnectPacketExtensions on ConnectPacket {
  /// Check if connect packet has session ID in data
  bool get hasSessionId {
    final Object? currentData = data;
    if (currentData is Map<String, dynamic>) {
      return currentData.containsKey('sid');
    }
    return false;
  }

  /// Get session ID from connect data if available
  String? get sessionId {
    final Object? currentData = data;
    if (currentData is Map<String, dynamic>) {
      return currentData['sid'] as String?;
    }
    return null;
  }
}

/// Extension methods for EventPacket
extension EventPacketExtensions on EventPacket {
  /// Get the event name from the packet
  String? get eventName {
    final Object? currentData = data;
    if (currentData is List && currentData.isNotEmpty) {
      return currentData.first as String?;
    }
    return null;
  }

  /// Get event arguments (excluding the event name)
  List<Object?> get eventArgs {
    final Object? currentData = data;
    if (currentData is List && currentData.length > 1) {
      return currentData.sublist(1);
    }
    return <Object?>[];
  }

  /// Get the number of arguments
  int get argCount => eventArgs.length;

  /// Check if event has arguments
  bool get hasArgs => argCount > 0;

  /// Check if this event needs acknowledgment
  bool get needsAck => hasId;
}

/// Extension methods for AckPacket
extension AckPacketExtensions on AckPacket {
  /// Get the number of acknowledgment values
  int get valueCount {
    final Object? currentData = data;
    if (currentData is List) {
      return currentData.length;
    }
    return 0;
  }

  /// Check if ACK has values
  bool get hasValues => valueCount > 0;

  /// Get first ACK value if available
  Object? get firstValue {
    final Object? currentData = data;
    if (currentData is List && currentData.isNotEmpty) {
      return currentData.first;
    }
    return null;
  }
}

/// Extension methods for ConnectErrorPacket
extension ConnectErrorPacketExtensions on ConnectErrorPacket {
  /// Get error message from packet
  String get errorMessage {
    final Object? currentData = data;
    if (currentData is Map<String, dynamic>) {
      return currentData['message']?.toString() ?? 'Unknown error';
    }
    return currentData?.toString() ?? 'Unknown error';
  }

  /// Check if error has an error code
  bool get hasErrorCode {
    final Object? currentData = data;
    if (currentData is Map<String, dynamic>) {
      return currentData.containsKey('code');
    }
    return false;
  }

  /// Get error code if available
  Object? get errorCode {
    final Object? currentData = data;
    if (currentData is Map<String, dynamic>) {
      return currentData['code'];
    }
    return null;
  }
}

/// Extension methods for packet validation
extension PacketValidation on SocketIOPacket {
  /// Validate that packet has required fields
  bool get isValid {
    // Basic validation
    if (type < CONNECT || type > BINARY_ACK) {
      return false;
    }

    // Type-specific validation
    switch (type) {
      case CONNECT:
      case CONNECT_ERROR:
        // Connect packets should have namespace
        return true;

      case EVENT:
      case BINARY_EVENT:
        // Event packets must have data
        return hasData;

      case ACK:
      case BINARY_ACK:
        // ACK packets must have an ID
        return hasId;

      case DISCONNECT:
        // Disconnect packets are always valid
        return true;

      default:
        return false;
    }
  }

  /// Get validation errors as a list
  List<String> getValidationErrors() {
    final List<String> errors = <String>[];

    if (type < CONNECT || type > BINARY_ACK) {
      errors.add('Invalid packet type: $type');
    }

    switch (type) {
      case EVENT:
      case BINARY_EVENT:
        if (!hasData) {
          errors.add('Event packet must have data');
        }
        final Object? currentData = data;
        if (currentData is List && currentData.isEmpty) {
          errors.add('Event data must not be empty');
        }
        break;

      case ACK:
      case BINARY_ACK:
        if (!hasId) {
          errors.add('ACK packet must have an ID');
        }
        break;
    }

    return errors;
  }

  /// Check if packet can be safely serialized
  bool get isSerializable {
    try {
      toMap();
      return true;
    } on Object {
      return false;
    }
  }
}
