import 'dart:io';
import 'package:at_lookup/src/connection/base_socket_connection.dart';


abstract class OutboundWebSocketConnection extends BaseSocketConnection {
  final WebSocket webSocket;

  OutboundWebSocketConnection(this.webSocket) : super(webSocket);

  void setIdleTime(int? idleTimeMillis);
}
