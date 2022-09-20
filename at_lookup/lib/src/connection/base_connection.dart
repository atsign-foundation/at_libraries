import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';

/// Base class for common socket operations
abstract class BaseConnection extends AtConnection {
  late final Socket _socket;
  StringBuffer? buffer;
  AtConnectionMetaData? metaData;

  BaseConnection(Socket? socket) {
    buffer = StringBuffer();
    socket?.setOption(SocketOption.tcpNoDelay, true);
    _socket = socket!;
  }

  @override
  AtConnectionMetaData? getMetaData() {
    return metaData;
  }

  @override
  Future<void> close() async {
    try {
      _socket.destroy();
      getMetaData()!.isClosed = true;
    } on Exception {
      getMetaData()!.isStale = true;
      // Ignore exception on a connection close
    } on Error {
      getMetaData()!.isStale = true;
      // Ignore error on a connection close
    }
  }

  @override
  Socket getSocket() {
    return _socket;
  }

  @override
  Future<void> write(String data) async {
    if (isInValid()) {
      //# Replace with specific exception
      throw ConnectionInvalidException('Connection is invalid');
    }
    try {
      getSocket().write(data);
      getMetaData()!.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      getMetaData()!.isStale = true;
    }
  }
}
