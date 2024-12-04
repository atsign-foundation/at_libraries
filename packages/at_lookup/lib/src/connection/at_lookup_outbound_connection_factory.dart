import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_websocket_connection_impl.dart';

import 'outbound_message_listener.dart';

/// This factory is responsible for creating the underlying connection,
/// an outbound connection wrapper, and the message listener for a
/// specific type of connection (e.g., `SecureSocket` or `WebSocket`).
abstract class AtLookupOutboundConnectionFactory<T, U> {
  /// Creates the underlying connection of type [T].
  Future<T> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig);

  /// Wraps the underlying connection of type [T] into an outbound connection [U].
  U createConnection(T underlying);

  /// Creates an [OutboundMessageListener] to manage messages for the given [U] connection.
  OutboundMessageListener createListener(U connection);
}

/// Factory class to create a secure outbound connection over [SecureSocket].
class AtLookupSecureSocketFactory extends AtLookupOutboundConnectionFactory<
    SecureSocket, OutboundConnection> {
  /// Creates a secure socket connection to the specified [host] and [port]
  /// using the given [secureSocketConfig]. Returns a [SecureSocket]
  @override
  Future<SecureSocket> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    return await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig);
  }

  /// Wraps the [SecureSocket] connection into an [OutboundConnection] instance.
  @override
  OutboundConnection createConnection(SecureSocket underlying) {
    return OutboundConnectionImpl(underlying);
  }

  /// Creates an [OutboundMessageListener] to manage messages for the secure
  /// socket-based [OutboundConnection].
  @override
  OutboundMessageListener createListener(OutboundConnection connection) {
    return OutboundMessageListener(connection);
  }
}

/// Factory class to create a WebSocket-based outbound connection.
class AtLookupWebSocketFactory extends AtLookupOutboundConnectionFactory<
    WebSocket, OutboundWebSocketConnection> {
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

  /// Wraps the [WebSocket] connection into an [OutboundWebSocketConnection] instance.
  @override
  OutboundWebSocketConnection createConnection(WebSocket underlying) {
    return OutboundWebsocketConnectionImpl(underlying);
  }

  /// Creates an [OutboundMessageListener] to manage messages for the
  /// WebSocket-based [OutboundWebSocketConnection].
  @override
  OutboundMessageListener createListener(
      OutboundWebSocketConnection connection) {
    return OutboundMessageListener(connection);
  }
}
