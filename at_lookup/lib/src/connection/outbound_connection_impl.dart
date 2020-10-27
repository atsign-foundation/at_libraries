import 'dart:io';
import 'outbound_connection.dart';

class OutboundConnectionImpl extends OutboundConnection {

  int outbound_idle_time = 600000; //default timeout 10 minutes

  OutboundConnectionImpl(Socket socket) : super(socket) {
    metaData = OutboundConnectionMetadata()..created = DateTime.now().toUtc();
  }

  int _getIdleTimeMillis() {
    var lastAccessedTime = getMetaData().lastAccessed;
    lastAccessedTime ??= getMetaData().created;
    var currentTime = DateTime.now().toUtc();
    return currentTime.difference(lastAccessedTime).inMilliseconds;
  }

  bool _isIdle() {
    return _getIdleTimeMillis() > outbound_idle_time;
  }

  @override
  bool isInValid() {
    return _isIdle() || getMetaData().isClosed || getMetaData().isStale;
  }

  @override
  void setIdleTime(int idleTimeMillis) {
    outbound_idle_time = idleTimeMillis;
  }
}
