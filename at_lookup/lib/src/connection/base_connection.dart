import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';

/// Base class for common socket operations
abstract class BaseConnection extends AtConnection {
  final Socket _socket;
  StringBuffer buffer;
  AtConnectionMetaData metaData;

  BaseConnection(this._socket) {
    buffer = StringBuffer();
  }

  @override
  AtConnectionMetaData getMetaData() {
    return metaData;
  }

  @override
  void close() {
    try {
      _socket.destroy();
      getMetaData().isClosed = true;
    } on Exception {
      getMetaData().isStale = true;
      // Ignore exception on a connection close
    } on Error {
      getMetaData().isStale = true;
      // Ignore error on a connection close
    }
  }

  @override
  Socket getSocket() {
    return _socket;
  }

  @override
  void write(String data) {
    if (isInValid()) {
      //# Replace with specific exception
      throw ConnectionInvalidException('Connection is invalid');
    }
    try {
      getSocket().write(data);
      getMetaData().lastAccessed = DateTime.now().toUtc();
    } on StateError {
      getMetaData().isStale = true;
      throw ConnectionInvalidException('StateError on write');
    } on SocketException {
      getMetaData().isStale = true;
      throw ConnectionInvalidException('Socket exception on write');
    } on Exception {
      getMetaData().isStale = true;
      throw ConnectionInvalidException('Exception on write');
    }
  }
}
