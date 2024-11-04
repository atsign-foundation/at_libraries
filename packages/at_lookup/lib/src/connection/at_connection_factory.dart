import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';

import 'outbound_message_listener.dart';


abstract class AtConnectionFactory<T, U> {
  Future<T> create(String host, String port, SecureSocketConfig secureSocketConfig);

  U outBoundConnectionFactory(T socket);

  OutboundMessageListener listenerFactory(U connection);

  // New method to indicate the connection type
  String get connectionType;
}

class SecureSocketFactory extends AtConnectionFactory<SecureSocket, OutboundConnection> {
  @override
  Future<SecureSocket> create(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    return await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig);
  }

  @override
  OutboundConnection outBoundConnectionFactory(SecureSocket socket) {
    return OutboundConnectionImpl(socket);
  }

  @override
  OutboundMessageListener listenerFactory(OutboundConnection connection) {
    return OutboundMessageListener(connection);
  }

  @override
  String get connectionType => 'SecureSocket';
}

class WebSocketFactory extends AtConnectionFactory<WebSocket, OutboundWebSocketConnection> {
  @override
  Future<WebSocket> create(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    final socket = await SecureSocketUtil.createSecureSocket(
        host, port, secureSocketConfig,
        isWebSocket: true);
    return socket as WebSocket;
  }

  @override
  OutboundWebSocketConnection outBoundConnectionFactory(WebSocket socket) {
    return OutboundWebsocketConnectionImpl(socket);
  }

  @override
  OutboundMessageListener listenerFactory(OutboundWebSocketConnection connection) {
    return OutboundMessageListener(connection);
  }

  @override
  String get connectionType => 'WebSocket';
}