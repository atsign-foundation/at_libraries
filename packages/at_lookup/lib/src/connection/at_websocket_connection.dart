import 'dart:async';
import 'dart:io';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';

/// WebSocket-specific connection class
class AtWebSocketConnection<T extends WebSocket> extends AtConnection {
  final T _webSocket;
  late final AtSignLogger logger;
  StringBuffer? buffer;

  AtWebSocketConnection(this._webSocket) {
    logger = AtSignLogger(runtimeType.toString());
    buffer = StringBuffer();
    metaData.created = DateTime.now().toUtc();
  }

  @override
  Future<void> close() async {
    if (metaData.isClosed) {
      logger.finer('close(): WebSocket connection is already closed');
      return;
    }

    try {
      logger.info('close(): closing WebSocket connection');
      await _webSocket.close();
    } catch (e) {
      // Ignore errors or exceptions on connection close
      logger.finer('Exception "$e" while closing WebSocket - ignoring');
      metaData.isStale = true;
    } finally {
      metaData.isClosed = true;
    }
  }

  @override
  T get underlying => _webSocket;

  @override
  FutureOr<void> write(String data) async {
    if (isInValid()) {
      throw ConnectionInvalidException(
          'write(): WebSocket connection is invalid');
    }

    try {
      _webSocket.add(data); // WebSocket uses add() to send data
      metaData.lastAccessed = DateTime.now().toUtc();
    } on Exception {
      metaData.isStale = true;
    }
  }
}
