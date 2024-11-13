import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';

/// Base class for common socket operations
abstract class BaseConnection<T extends Socket> extends AtConnection {
  final T _socket;
  late final AtSignLogger logger;
  StringBuffer? buffer;
  AtConnectionMetaData? metaData;

  BaseConnection(this._socket) {
    logger = AtSignLogger(runtimeType.toString());
    buffer = StringBuffer();
    _socket.setOption(SocketOption.tcpNoDelay, true);
  }

  @override
  AtConnectionMetaData? getMetaData() {
    return metaData;
  }

  @override
  Future<void> close() async {
    if (getMetaData()!.isClosed) {
      logger.finer('close(): connection is already closed');
      return;
    }

    try {
      var address = underlying.remoteAddress;
      var port = underlying.remotePort;

      logger.info('close(): calling socket.destroy()'
          ' on connection to $address:$port');
      _socket.destroy();
    } catch (e) {
      // Ignore errors or exceptions on a connection close
      logger.finer('Exception "$e" while destroying socket - ignoring');
      getMetaData()!.isStale = true;
    } finally {
      getMetaData()!.isClosed = true;
    }
  }

   @override
  T get underlying => _socket;

  @override
  Future<void> write(String data) async {
    if (isInValid()) {
      //# Replace with specific exception
      throw ConnectionInvalidException('write(): Connection is invalid');
    }
    try {
      underlying.write(data);
      getMetaData()!.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      getMetaData()!.isStale = true;
    }
  }
}
