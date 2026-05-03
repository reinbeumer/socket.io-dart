// socket.dart
//
// Purpose:
//
// Description:
//
// History:
//    17/02/2017, Created by jumperchen
//
// Copyright (C) 2017 Potix Corporation. All Rights Reserved.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../models/callbacks_models.dart';
import '../util/event_emitter.dart';
import '../value_objects/transport_name_vo.dart';
import 'connect.dart';
import 'server.dart';
import 'transport/transports.dart';

/// Client class (abstract).
///
/// @api private
class Socket extends EventEmitter {
  static final Logger _logger = Logger('socket_io:engine.Socket');
  String id;
  Server server;
  Transport transport;
  bool upgrading = false;
  bool upgraded = false;
  String readyState = 'opening';
  List<Map<String, dynamic>> writeBuffer = <Map<String, dynamic>>[];
  List<PacketCallback> packetsFn = <PacketCallback>[];
  List<PacketCallback> sentCallbackFn = <PacketCallback>[];
  List<CleanupCallback> cleanupFn = <CleanupCallback>[];
  SocketConnect connect;
  late InternetAddress remoteAddress;
  Timer? checkIntervalTimer;
  Timer? upgradeTimeoutTimer;
  Timer? pingTimeoutTimer;

  Socket(this.id, this.server, this.transport, this.connect) {
    // Cache IP since it might not be in the req later
    remoteAddress = connect.request.connectionInfo!.remoteAddress;

    checkIntervalTimer = null;
    upgradeTimeoutTimer = null;
    pingTimeoutTimer = null;

    setTransport(transport);
    onOpen();
  }

  /// Called upon transport considered open.
  ///
  /// @api private

  void onOpen() {
    readyState = 'open';

    // sends an `open` packet
    transport.sid = id;
    sendPacket('open',
        data: json.encode(<String, Object>{
          'sid': id,
          'upgrades': getAvailableUpgrades(),
          'pingInterval': server.pingInterval,
          'pingTimeout': server.pingTimeout
        }),
        options: const <String, bool>{'compress': false});

//    if (this.server.initialPacket != null) {
//      this.sendPacket('message', data: this.server.initialPacket);
//    }

    emit('open');
    setPingTimeout();
  }

  /// Called upon transport packet.
  ///
  /// @param {Object} packet
  /// @api private
  void onPacket(final Map<String, dynamic> packet) {
    if ('open' == readyState) {
      // export packet event
      _logger.fine('packet');
      emit('packet', packet);

      // Reset ping timeout on any packet, incoming data is a good sign of
      // other side's liveness
      setPingTimeout();
      switch (packet['type']) {
        case 'ping':
          _logger.fine('got ping');
          sendPacket('pong', options: const <String, bool>{'compress': false});
          emit('heartbeat');
          break;

        case 'error':
          onClose('parse error');
          break;

        case 'message':
          final dynamic data = packet['data'];
          emit('data', data);
          emit('message', data);
          break;
      }
    } else {
      _logger.fine('packet received with closed socket');
    }
  }

  /// Called upon transport error.
  ///
  /// @param {Error} error object
  /// @api private
  void onError(final Object err) {
    _logger.fine('transport error');
    onClose('transport error', err);
  }

  /// Sets and resets ping timeout timer based on client pings.
  ///
  /// @api private
  void setPingTimeout() {
    if (pingTimeoutTimer != null) {
      pingTimeoutTimer!.cancel();
    }
    pingTimeoutTimer = Timer((server.pingInterval + server.pingTimeout).value, () {
      onClose('ping timeout');
    });
  }

  /// Attaches handlers for the given transport.
  ///
  /// @param {Transport} transport
  /// @api private
  void setTransport(final Transport transport) {
    void onErrorHandler(final dynamic data) => onError(data);
    void onPacketHandler(final dynamic data) => onPacket(data as Map<String, dynamic>);
    void flushHandler(final dynamic _) => flush();
    void onCloseHandler(final dynamic _) {
      onClose('transport close');
    }

    this.transport = transport;
    transport
      ..on('error', onErrorHandler)
      ..on('packet', onPacketHandler)
      ..on('drain', flushHandler)
      ..on('close', onCloseHandler);
    // this function will manage packet events (also message callbacks)
    this.transport = transport;
  }

  /// Upgrades socket to the given transport
  ///
  /// @param {Transport} transport
  /// @api private
  void maybeUpgrade(final Transport transport) {
    _logger.fine('might upgrade socket transport from ${this.transport.name} to ${transport.name}');

    upgrading = true;
    final Map<String, CleanupCallback> cleanupFn = <String, CleanupCallback>{};

    void check() {
      if ('polling' == this.transport.name && this.transport.writable == true) {
        _logger.fine('writing a noop packet to polling for fast upgrade');
        this.transport.send(<Map<String, dynamic>>[
          <String, String>{'type': 'noop'}
        ]);
      }
    }

    void onPacketHandler(final dynamic data) {
      final Map<String, dynamic> packet = data as Map<String, dynamic>;
      if ('ping' == packet['type'] && 'probe' == packet['data']) {
        transport.send(<Map<String, dynamic>>[
          <String, String>{'type': 'pong', 'data': 'probe'}
        ]);
        emit('upgrading', transport);
        if (checkIntervalTimer != null) {
          checkIntervalTimer!.cancel();
        }
        checkIntervalTimer = Timer.periodic(const Duration(milliseconds: 100), (final _) => check());
      } else if ('upgrade' == packet['type'] && readyState != 'closed') {
        _logger.fine('got upgrade packet - upgrading');
        cleanupFn['cleanup']!();
        this.transport.discard();
        upgraded = true;
        clearTransport();
        setTransport(transport);
        emit('upgrade', transport);
        setPingTimeout();
        flush();
        if (readyState == 'closing') {
          transport.close(() {
            this.onClose('forced close');
          });
        }
      } else {
        cleanupFn['cleanup']!();
        transport.close();
      }
    }

    void onErrorHandler(final dynamic err) {
      _logger.fine('client did not complete upgrade - $err');
      cleanupFn['cleanup']!();
      transport.close();
    }

    void onTransportClose(final dynamic _) {
      onErrorHandler('transport closed');
    }

    void onClose(final dynamic _) {
      onErrorHandler('socket closed');
    }

    void cleanup() {
      upgrading = false;
      checkIntervalTimer?.cancel();
      checkIntervalTimer = null;

      upgradeTimeoutTimer?.cancel();
      upgradeTimeoutTimer = null;

      transport
        ..off('packet', onPacketHandler)
        ..off('close', onTransportClose)
        ..off('error', onErrorHandler);
      off('close', onClose);
    }

    cleanupFn['cleanup'] = cleanup;

    // set transport upgrade timer
    upgradeTimeoutTimer = Timer(server.upgradeTimeout.value, () {
      _logger.fine('client did not complete upgrade - closing transport');
      cleanupFn['cleanup']!();
      if ('open' == transport.readyState) {
        transport.close();
      }
    });

    transport
      ..on('packet', onPacketHandler)
      ..once('close', onTransportClose)
      ..once('error', onErrorHandler);
    once('close', onClose);
  }

  /// Clears listeners and timers associated with current transport.
  ///
  /// @api private
  void clearTransport() {
    final int toCleanUp = cleanupFn.length;

    for (int i = 0; i < toCleanUp; i++) {
      final CleanupCallback cleanup = cleanupFn.removeAt(0);
      cleanup();
    }

    // silence further transport errors and prevent uncaught exceptions
    transport
      ..on('error', (final _) {
        _logger.fine('error triggered by discarded transport');
      })

      // ensure transport won't stay open
      ..close();

    pingTimeoutTimer?.cancel();
  }

  /// Called upon transport considered closed.
  /// Possible reasons: `ping timeout`, `client error`, `parse error`,
  /// `transport error`, `server close`, `transport close`
  void onClose(final String reason, [final Object? description]) {
    if ('closed' != readyState) {
      readyState = 'closed';
      pingTimeoutTimer?.cancel();
      checkIntervalTimer?.cancel();
      checkIntervalTimer = null;
      upgradeTimeoutTimer?.cancel();

      // clean writeBuffer in next tick, so developers can still
      // grab the writeBuffer on 'close' event
      scheduleMicrotask(() {
        writeBuffer = <Map<String, dynamic>>[];
      });
      packetsFn = <PacketCallback>[];
      sentCallbackFn = <PacketCallback>[];
      clearTransport();
      emit('close', <Object?>[reason, description]);
    }
  }

  /// Setup and manage send callback
  ///
  /// @api private
  void setupSendCallback() {
    // the message was sent successfully, execute the callback
    void onDrain(final _) {
      if (sentCallbackFn.isNotEmpty) {
        final dynamic seqFn = sentCallbackFn[0];
        if (seqFn is Function) {
          _logger.fine('executing send callback');
          seqFn(transport);
        }
      }
    }

    transport.on('drain', onDrain);

    cleanupFn.add(() {
      transport.off('drain', onDrain);
    });
  }

  /// Sends a message packet.
  ///
  /// @param {String} message
  /// @param {Object} options
  /// @param {Function} callback
  /// @return {Socket} for chaining
  /// @api public
  void send(final Object? data, final Map<String, bool> options, [final PacketCallback? callback]) =>
      write(data, options, callback);
  Socket write(final Object? data, final Map<String, bool> options, [final PacketCallback? callback]) {
    sendPacket('message', data: data, options: options, callback: callback);
    return this;
  }

  /// Sends a packet.
  ///
  /// @param {String} packet type
  /// @param {String} optional, data
  /// @param {Object} options
  /// @api private
  void sendPacket(final String type,
      {final Object? data, required final Map<String, bool> options, final PacketCallback? callback}) {
    // ensure default for compress
    final Map<String, bool> normalizedOptions = <String, bool>{
      'compress': options['compress'] ?? true,
    };

    if ('closing' != readyState && 'closed' != readyState) {
      final Map<String, dynamic> packet = <String, dynamic>{'type': type, 'options': normalizedOptions};
      if (data != null) packet['data'] = data;

      // exports packetCreate event
      emit('packetCreate', packet);

      writeBuffer.add(packet);

      // add send callback to object, if defined
      if (callback != null) {
        packetsFn.add(callback);
      }

      flush();
    }
  }

  /// Attempts to flush the packets buffer.
  ///
  /// @api private
  void flush() {
    if ('closed' != readyState && transport.writable == true && writeBuffer.isNotEmpty) {
      _logger.fine('flushing buffer to transport');
      emit('flush', writeBuffer);
      server.emit('flush', <Object>[this, writeBuffer]);
      final List<Map<String, dynamic>> wbuf = List<Map<String, dynamic>>.from(writeBuffer);
      writeBuffer = <Map<String, dynamic>>[];
      if (transport.supportsFraming == false) {
        sentCallbackFn.add((final Object? value) => packetsFn.forEach((final PacketCallback f) => f(value)));
      } else {
        sentCallbackFn.addAll(packetsFn);
      }
      packetsFn = <PacketCallback>[];
      transport.send(wbuf);
      emit('drain');
      server.emit('drain', this);
    }
  }

  /// Get available upgrades for this socket.
  ///
  /// @api private
  List<dynamic> getAvailableUpgrades() {
    final List<dynamic> availableUpgrades = <dynamic>[];
    final List<String> allUpgrades = server.upgrades(transport.name!);
    for (int i = 0, l = allUpgrades.length; i < l; ++i) {
      final String upg = allUpgrades[i];
      if (server.transports.any((final TransportName t) => t.value == upg)) {
        availableUpgrades.add(upg);
      }
    }
    return availableUpgrades;
  }

  /// Closes the socket and underlying transport.
  ///
  /// @param {Boolean} optional, discard
  /// @return {Socket} for chaining
  /// @api public

  void close([final bool discard = false]) {
    if ('open' != readyState) return;
    readyState = 'closing';

    if (writeBuffer.isNotEmpty) {
      once('drain', (final _) => closeTransport(discard));
      return;
    }

    closeTransport(discard);
  }

  /// Closes the underlying transport.
  ///
  /// @param {Boolean} discard
  /// @api private
  void closeTransport(final bool discard) {
    if (discard == true) transport.discard();
    transport.close(() => onClose('forced close'));
  }
}
