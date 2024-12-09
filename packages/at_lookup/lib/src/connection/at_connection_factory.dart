import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/at_socket_connection.dart';
import 'package:at_lookup/src/connection/at_websocket_connection.dart';

import 'at_message_listener.dart';

/// This factory is responsible for creating the underlying connection,
/// an connection wrapper, and the message listener for a
/// specific type of connection (e.g., `SecureSocket` or `WebSocket`).
abstract class AtConnectionFactory<T, U> {
  /// Creates the underlying connection of type [T].
  Future<T> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig);

  /// Wraps the underlying connection of type [T] into an connection [U].
  U createConnection(T underlying);

  /// Creates an [AtMessageListener] to manage messages for the given [U] connection.
  AtMessageListener createListener(U connection);
}

/// Factory class to create a secure connection over [SecureSocket].
class AtLookupSecureSocketFactory
    extends AtConnectionFactory<SecureSocket, AtConnection> {
  /// Creates a secure socket connection to the specified [host] and [port]
  /// using the given [secureSocketConfig]. Returns a [SecureSocket]
  @override
  Future<SecureSocket> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    return await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig);
  }

  /// Wraps the [SecureSocket] connection into an [AtConnection] instance.
  @override
  AtConnection createConnection(SecureSocket underlying) {
    return AtSocketConnection(underlying);
  }

  /// Creates an [AtMessageListener] to manage messages for the secure
  /// socket-based [AtConnection].
  @override
  AtMessageListener createListener(AtConnection connection) {
    return AtMessageListener(connection);
  }
}

/// Factory class to create a WebSocket-based connection.
class AtLookupWebSocketFactory
    extends AtConnectionFactory<WebSocket, AtConnection> {
  /// Creates a WebSocket connection to the specified [host] and [port]
  /// using the given [secureSocketConfig].
  @override
  Future<WebSocket> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    final socket = await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig,
        isWebSocket: true);
    return socket as WebSocket;
  }

  /// Wraps the [WebSocket] connection into an [AtConnection] instance.
  @override
  AtConnection createConnection(underlying) {
    return AtWebSocketConnection(underlying);
  }

  /// Creates an [AtMessageListener] to manage messages for the
  /// WebSocket-based [AtConnection].
  @override
  AtMessageListener createListener(AtConnection connection) {
    return AtMessageListener(connection);
  }
}
