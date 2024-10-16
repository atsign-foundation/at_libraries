import 'dart:io';
import 'package:at_lookup/src/connection/base_websocket_connection.dart';


abstract class OutboundWebSocketConnection extends BaseWebSocketConnection {
  final WebSocket webSocket;

  OutboundWebSocketConnection(this.webSocket) : super(webSocket);

  void setIdleTime(int? idleTimeMillis);
}
