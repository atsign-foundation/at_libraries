import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';

/// WebSocket-specific connection class
abstract class BaseWebSocketConnection extends AtConnection {
  final WebSocket _webSocket;
  late final AtSignLogger logger;
  StringBuffer? buffer;
  AtConnectionMetaData? metaData;

  BaseWebSocketConnection(this._webSocket) {
    logger = AtSignLogger(runtimeType.toString());
    buffer = StringBuffer();
  }

  @override
  AtConnectionMetaData? getMetaData() {
    return metaData;
  }

  @override
  Future<void> close() async {
    if (getMetaData()!.isClosed) {
      logger.finer('close(): WebSocket connection is already closed');
      return;
    }

    try {
      logger.info('close(): closing WebSocket connection');
      await _webSocket.close();
    } catch (e) {
      // Ignore errors or exceptions on connection close
      logger.finer('Exception "$e" while closing WebSocket - ignoring');
      getMetaData()!.isStale = true;
    } finally {
      getMetaData()!.isClosed = true;
    }
  }

  @override
  WebSocket get underlying => _webSocket;

  @override
  Future<void> write(String data) async {
    if (isInValid()) {
      throw ConnectionInvalidException(
          'write(): WebSocket connection is invalid');
    }

    try {
      _webSocket.add(data); // WebSocket uses add() to send data
      getMetaData()!.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      getMetaData()!.isStale = true;
    }
  }
  
}
