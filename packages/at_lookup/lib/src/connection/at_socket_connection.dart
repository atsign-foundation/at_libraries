import 'dart:async';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';

/// Base class for common socket operations
class AtSocketConnection<T extends Socket> extends AtConnection {
  final T _socket;
  final AtSignLogger logger = AtSignLogger('AtSocketConnection');
  final StringBuffer buffer = StringBuffer();

  AtSocketConnection(this._socket) {
    _socket.setOption(SocketOption.tcpNoDelay, true);
    metaData.created = DateTime.now().toUtc();
  }

  @override
  Future<void> close() async {
    if (metaData.isClosed) {
      logger.finer('close(): connection is already closed');
      return;
    }

    try {
      var address = underlying.remoteAddress;
      var port = underlying.remotePort;

      logger.info(
          'close(): calling socket.destroy() on connection to $address:$port');
      underlying.destroy();
    } catch (e) {
      // Ignore errors or exceptions on a connection close
      logger.finer('Exception "$e" while destroying socket - ignoring');
      metaData.isStale = true;
    } finally {
      metaData.isClosed = true;
    }
  }

  @override
  T get underlying => _socket;

  @override
  FutureOr<void> write(String data) async {
    if (isInValid()) {
      throw ConnectionInvalidException('write(): Connection is invalid');
    }
    try {
      underlying.write(data);
      metaData.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      metaData.isStale = true;
    }
  }
}
