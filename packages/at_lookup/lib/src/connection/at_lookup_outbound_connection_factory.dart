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
  ///
  /// Takes [host], [port], and [secureSocketConfig] as parameters to establish
  /// a secure connection based on the provided configuration.
  Future<T> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig);

  /// Wraps the underlying connection of type [T] into an outbound connection [U].
  U outBoundConnectionFactory(T underlying);

  /// Creates an [OutboundMessageListener] to manage messages for the given [U] connection.
  OutboundMessageListener atLookupSocketListenerFactory(U connection);
}

/// Factory class to create a secure outbound connection over [SecureSocket].
///
/// This class handles the creation of a secure socket-based connection,
/// its outbound connection wrapper, and the corresponding message listener.
class AtLookupSecureSocketFactory extends AtLookupOutboundConnectionFactory<
    SecureSocket, OutboundConnection> {
  /// Creates a secure socket connection to the specified [host] and [port]
  /// using the given [secureSocketConfig].
  ///
  /// Returns a [SecureSocket] that establishes a secure connection
  @override
  Future<SecureSocket> createUnderlying(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    return await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig);
  }

  /// Wraps the [SecureSocket] connection into an [OutboundConnection] instance.
  @override
  OutboundConnection outBoundConnectionFactory(SecureSocket underlying) {
    return OutboundConnectionImpl(underlying);
  }

  /// Creates an [OutboundMessageListener] to manage messages for the secure
  /// socket-based [OutboundConnection].
  @override
  OutboundMessageListener atLookupSocketListenerFactory(
      OutboundConnection connection) {
    return OutboundMessageListener(connection);
  }
}

/// Factory class to create a WebSocket-based outbound connection.
///
/// This class handles the creation of a WebSocket connection,
/// its outbound connection wrapper, and the associated message listener.
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
  ///
  /// This outbound connection manages WebSocket-specific message handling and
  /// provides additional methods for WebSocket communication.
  @override
  OutboundWebSocketConnection outBoundConnectionFactory(WebSocket underlying) {
    return OutboundWebsocketConnectionImpl(underlying);
  }

  /// Creates an [OutboundMessageListener] to manage messages for the
  /// WebSocket-based [OutboundWebSocketConnection].
  @override
  OutboundMessageListener atLookupSocketListenerFactory(
      OutboundWebSocketConnection connection) {
    return OutboundMessageListener(connection);
  }
}
