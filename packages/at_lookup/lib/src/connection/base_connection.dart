import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';

/// Base class for common socket and websocket operations
abstract class BaseConnection implements SocketConnection, WebSocketConnection {
  late final AtSignLogger logger;
  late final dynamic _connection; // Can be either Socket or WebSocket
  StringBuffer? buffer;
  AtConnectionMetaData? metaData;

  // Constructor for both Socket and WebSocket connections
  BaseConnection(dynamic connection) {
    logger = AtSignLogger(runtimeType.toString());
    buffer = StringBuffer();

    if (connection is Socket) {
      connection.setOption(SocketOption.tcpNoDelay, true);
    }

    _connection = connection;
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
      if (_connection is Socket) {
        var address = (_connection as Socket).remoteAddress;
        var port = (_connection as Socket).remotePort;

        logger.info(
            'close(): calling socket.destroy() on connection to $address:$port');
        (_connection as Socket).destroy();
      } else if (_connection is WebSocket) {
        logger.info('close(): closing WebSocket connection');
        await (_connection as WebSocket).close();
      }
    } catch (e) {
      // Ignore errors or exceptions on a connection close
      logger.finer('Exception "$e" while closing connection - ignoring');
      getMetaData()!.isStale = true;
    } finally {
      getMetaData()!.isClosed = true;
    }
  }

  @override
  Future<void> write(String data) async {
    if (isInValid()) {
      throw ConnectionInvalidException('write(): Connection is invalid');
    }
    try {
      if (_connection is Socket) {
        (_connection as Socket).write(data);
      } else if (_connection is WebSocket) {
        (_connection as WebSocket)
            .add(data); // WebSocket uses `add` to write data
      }

      getMetaData()!.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      getMetaData()!.isStale = true;
    }
  }

  @override
  bool isInValid() {
    return metaData!.isStale || metaData!.isClosed;
  }

  /// Specific getter for Socket connection
  @override
  Socket getSocket() {
    if (_connection is Socket) {
      return _connection as Socket;
    }
    throw Exception('Connection is not a Socket');
  }

  /// Specific getter for WebSocket connection
  @override
  WebSocket getWebSocket() {
    if (_connection is WebSocket) {
      return _connection as WebSocket;
    }
    throw Exception('Connection is not a WebSocket');
  }
}
