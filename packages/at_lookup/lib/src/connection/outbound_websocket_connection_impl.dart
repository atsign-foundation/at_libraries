import 'dart:io';
import 'outbound_websocket_connection.dart';
import 'outbound_connection.dart';

class OutboundWebsocketConnectionImpl<T extends WebSocket>
    extends OutboundWebSocketConnection {
  int? outboundIdleTime = 600000; //default timeout 10 minutes

  OutboundWebsocketConnectionImpl(T websocket) : super(websocket) {
    metaData = OutboundConnectionMetadata()..created = DateTime.now().toUtc();
  }

  int _getIdleTimeMillis() {
    var lastAccessedTime = getMetaData()!.lastAccessed;
    lastAccessedTime ??= getMetaData()!.created;
    var currentTime = DateTime.now().toUtc();
    return currentTime.difference(lastAccessedTime!).inMilliseconds;
  }

  bool _isIdle() {
    return _getIdleTimeMillis() > outboundIdleTime!;
  }

  @override
  bool isInValid() {
    return _isIdle() || getMetaData()!.isClosed || getMetaData()!.isStale;
  }

  @override
  void setIdleTime(int? idleTimeMillis) {
    outboundIdleTime = idleTimeMillis;
  }
}
