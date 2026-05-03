/*
event_emitter.dart

Purpose:

Description:

History:
    11/23/2016, Created by Henri Chen<henrichen@potix.com>

Copyright (C) 2016 Potix Corporation. All Rights Reserved.
*/
import 'dart:collection' show HashMap;

/// Union type for Socket.IO event data - represents the actual types used in the library
typedef SocketIOEventData = dynamic;

/// More specific type constraints for Socket.IO events
/// This represents the actual data types passed in Socket.IO events:
/// - String: Simple text messages
/// - Map<String, dynamic>: JSON-like objects (connection data, error objects)
/// - List<dynamic>: Arrays of mixed data (event arguments)
/// - int/num: Numeric values (IDs, counts, etc.)
/// - bool: Boolean flags
/// - Socket: Socket objects for connection events
/// - null: Empty events
bool isValidSocketIOData(final dynamic data) =>
    data == null ||
    data is String ||
    data is num ||
    data is bool ||
    data is Map<String, dynamic> ||
    data is List<dynamic> ||
    data.runtimeType.toString().contains('Socket'); // Allow Socket objects

/// Handler type for handling the event emitted by an [EventEmitter].
/// Uses SocketIOEventData to be more explicit about expected types
typedef EventHandler<T> = void Function(T data);

/// Generic event emitting and handling.
class EventEmitter {
  /// Mapping of events to a list of event handlers
  HashMap<String, List<EventHandler<SocketIOEventData>>> _events =
      HashMap<String, List<EventHandler<SocketIOEventData>>>();

  /// Mapping of events to a list of one-time event handlers
  Map<String, List<EventHandler<SocketIOEventData>>> _eventsOnce =
      HashMap<String, List<EventHandler<SocketIOEventData>>>();

  /// This function triggers all the handlers currently listening
  /// to [event] and passes them [data].
  void emit(final String event, [final SocketIOEventData data]) {
    // Validate data type in debug mode
    assert(isValidSocketIOData(data), 'Invalid data type for Socket.IO event: {data.runtimeType}');

    final List<EventHandler<SocketIOEventData>>? list0 = _events[event];
    // todo: try to optimize this. Maybe remember the off() handlers and remove later?
    // handler might be off() inside handler; make a copy first
    final List<EventHandler<SocketIOEventData>>? list =
        list0 != null ? List<EventHandler<SocketIOEventData>>.from(list0) : null;
    list?.forEach((final EventHandler<SocketIOEventData> handler) {
      handler(data);
    });

    _eventsOnce.remove(event)?.forEach((final EventHandler<SocketIOEventData> handler) {
      handler(data);
    });
  }

  /// This function binds the [handler] as a listener to the [event]
  void on(final String event, final EventHandler<SocketIOEventData> handler) {
    _events.putIfAbsent(event, () => <EventHandler<SocketIOEventData>>[]);
    _events[event]!.add(handler);
  }

  /// This function binds the [handler] as a listener to the first
  /// occurrence of the [event]. When [handler] is called once,
  /// it is removed.
  void once(final String event, final EventHandler<SocketIOEventData> handler) {
    _eventsOnce.putIfAbsent(event, () => <EventHandler<SocketIOEventData>>[]);
    _eventsOnce[event]!.add(handler);
  }

  /// This function attempts to unbind the [handler] from the [event]
  void off(final String event, [final EventHandler<SocketIOEventData>? handler]) {
    if (handler != null) {
      _events[event]?.remove(handler);
      _eventsOnce[event]?.remove(handler);
      if (_events[event]?.isEmpty == true) {
        _events.remove(event);
      }
      if (_eventsOnce[event]?.isEmpty == true) {
        _eventsOnce.remove(event);
      }
    } else {
      _events.remove(event);
      _eventsOnce.remove(event);
    }
  }

  /// This function unbinds all the handlers for all the events.
  void clearListeners() {
    _events = HashMap<String, List<EventHandler<SocketIOEventData>>>();
    _eventsOnce = HashMap<String, List<EventHandler<SocketIOEventData>>>();
  }

  /// Returns whether the event has registered.
  bool hasListeners(final String event) => _events[event]?.isNotEmpty == true || _eventsOnce[event]?.isNotEmpty == true;
}

/// Type-safe event emitter for specific event data types
///
/// This provides a strongly-typed alternative to EventEmitter where you can
/// specify the type of data that will be emitted/handled for events.
///
/// Example:
/// ```dart
/// final TypedEventEmitter<String> stringEmitter = TypedEventEmitter<String>();
/// stringEmitter.on('message', (String data) => print('Received: $data'));
/// stringEmitter.emit('message', 'Hello World');
/// ```
class TypedEventEmitter<T> {
  /// Mapping of events to a list of event handlers
  HashMap<String, List<EventHandler<T>>> _events = HashMap<String, List<EventHandler<T>>>();

  /// Mapping of events to a list of one-time event handlers
  Map<String, List<EventHandler<T>>> _eventsOnce = HashMap<String, List<EventHandler<T>>>();

  /// This function triggers all the handlers currently listening
  /// to [event] and passes them [data].
  void emit(final String event, final T data) {
    final List<EventHandler<T>>? list0 = _events[event];
    // handler might be off() inside handler; make a copy first
    final List<EventHandler<T>>? list = list0 != null ? List<EventHandler<T>>.from(list0) : null;
    list?.forEach((final EventHandler<T> handler) {
      handler(data);
    });

    _eventsOnce.remove(event)?.forEach((final EventHandler<T> handler) {
      handler(data);
    });
  }

  /// This function binds the [handler] as a listener to the [event]
  void on(final String event, final EventHandler<T> handler) {
    _events.putIfAbsent(event, () => <EventHandler<T>>[]);
    _events[event]!.add(handler);
  }

  /// This function binds the [handler] as a listener to the first
  /// occurrence of the [event]. When [handler] is called once,
  /// it is removed.
  void once(final String event, final EventHandler<T> handler) {
    _eventsOnce.putIfAbsent(event, () => <EventHandler<T>>[]);
    _eventsOnce[event]!.add(handler);
  }

  /// This function attempts to unbind the [handler] from the [event]
  void off(final String event, [final EventHandler<T>? handler]) {
    if (handler != null) {
      _events[event]?.remove(handler);
      _eventsOnce[event]?.remove(handler);
      if (_events[event]?.isEmpty == true) {
        _events.remove(event);
      }
      if (_eventsOnce[event]?.isEmpty == true) {
        _eventsOnce.remove(event);
      }
    } else {
      _events.remove(event);
      _eventsOnce.remove(event);
    }
  }

  /// This function unbinds all the handlers for all the events.
  void clearListeners() {
    _events = HashMap<String, List<EventHandler<T>>>();
    _eventsOnce = HashMap<String, List<EventHandler<T>>>();
  }

  /// Returns whether the event has registered.
  bool hasListeners(final String event) => _events[event]?.isNotEmpty == true || _eventsOnce[event]?.isNotEmpty == true;
}
