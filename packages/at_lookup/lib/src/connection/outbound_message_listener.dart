import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';
import 'package:meta/meta.dart';

/// Listener class for messages received by [RemoteSecondary]
class OutboundMessageListener {
  final logger = AtSignLogger('OutboundMessageListener');
  late ByteBuffer _buffer;
  final Queue _queue = Queue();
  final AtConnection _connection;
  Function? syncCallback;
  final int newLineCodeUnit = 10;
  final int atCharCodeUnit = 64;
  late DateTime _lastReceivedTime;

  OutboundMessageListener(this._connection, {int bufferCapacity = 10240000}) {
    _buffer = ByteBuffer(capacity: bufferCapacity);
  }

  /// Listens to the underlying connection's socket or WebSocket if the connection is created.
  /// @throws [AtConnectException] if the connection is not yet created
  void listen() {
    logger.finest('Calling socket.listen within runZonedGuarded block');

    runZonedGuarded(() {
      // Handling Socket or WebSocket dynamically
      final connection = _connection.getSocket();
      if (connection is Socket) {
        connection.listen(messageHandler,
            onDone: onSocketDone, onError: onSocketError);
      } else if (connection is WebSocket) {
        connection.listen(messageHandler,
            onDone: onSocketDone, onError: onSocketError);
      } else {
        throw AtConnectException('Unsupported connection type');
      }
    }, (Object error, StackTrace st) {
      logger.warning(
          'runZonedGuarded received socket error $error - calling onSocketError() to close connection');
      onSocketError(error);
    });
  }

  /// Logs the error and closes the [OutboundConnection]
  @visibleForTesting
  void onSocketError(Object error) async {
    logger.finest(
        'outbound socket onError handler called - calling closeConnection - error was $error');
    await closeConnection();
    logger.finest(
        'outbound socket onError handler called - closeConnection complete');
  }

  /// Closes the [OutboundConnection]
  @visibleForTesting
  void onSocketDone() async {
    logger.finest(
        'outbound socket onDone handler called - calling closeConnection');
    await closeConnection();
    logger.finest(
        'outbound socket onDone handler called - closeConnection complete');
  }

  /// Handles messages on the inbound client's connection and calls the verb executor
  /// Closes the inbound connection in case of any error.
  /// Throw a [BufferOverFlowException] if buffer is unable to hold incoming data
  Future<void> messageHandler(dynamic data) async {
    String result;
    int offset;
    _lastReceivedTime = DateTime.now();

    List<int> byteData;

    // Handle data based on connection type
    if (data is String) {
      byteData = utf8.encode(data);
    } else if (data is List<int>) {
      byteData = data;
    } else {
      throw AtException('Unsupported message format');
    }

    _checkBufferOverFlow(byteData);

    if (byteData.contains(newLineCodeUnit)) {
      offset = byteData.lastIndexOf(newLineCodeUnit);
      var dataSubList = byteData.getRange(0, offset).toList();
      _buffer.append(dataSubList);
    } else {
      offset = 0;
    }

    for (int element = offset; element < byteData.length; element++) {
      if (byteData[element] == atCharCodeUnit &&
          (_buffer.length() > 0 && _buffer.getData().last == newLineCodeUnit)) {
        List<int> temp = (_buffer.getData().toList())..removeLast();
        result = utf8.decode(temp);
        result = _stripPrompt(result);
        logger.finer('RECEIVED $result');
        _queue.add(result);
        _buffer.clear();
        _buffer.addByte(byteData[element]);
      } else {
        _buffer.addByte(byteData[element]);
      }
    }
  }

  _checkBufferOverFlow(List<int> data) {
    if (_buffer.isOverFlow(data)) {
      int bufferLength = (_buffer.length() + data.length) as int;
      _buffer.clear();
      throw BufferOverFlowException(
          'data length exceeded the buffer limit. Data length : $bufferLength and Buffer capacity ${_buffer.capacity}');
    }
  }

  String _stripPrompt(String result) {
    var colonIndex = result.indexOf(':');
    var responsePrefix = result.substring(0, colonIndex);
    var response = result.substring(colonIndex);
    if (responsePrefix.contains('@')) {
      responsePrefix =
          responsePrefix.substring(responsePrefix.lastIndexOf('@') + 1);
    }
    return '$responsePrefix$response';
  }

  Future<String> read(
      {int maxWaitMilliSeconds = 90000,
      int transientWaitTimeMillis = 10000}) async {
    String result;
    _lastReceivedTime = DateTime.now();
    var startTime = DateTime.now();
    while (true) {
      var queueLength = _queue.length;
      if (queueLength > 0) {
        result = _queue.removeFirst();
        if (_isValidResponse(result)) {
          return result;
        }
        _buffer.clear();
        throw AtLookUpException('AT0014', 'Unexpected response found');
      }

      if (DateTime.now().difference(startTime).inMilliseconds >
          maxWaitMilliSeconds) {
        _buffer.clear();
        await closeConnection();
        throw AtTimeoutException(
            'Full response not received after $maxWaitMilliSeconds millis from remote secondary');
      }

      if (DateTime.now().difference(_lastReceivedTime).inMilliseconds >
          transientWaitTimeMillis) {
        _buffer.clear();
        await closeConnection();
        throw AtTimeoutException(
            'Waited for $transientWaitTimeMillis millis. No response after $_lastReceivedTime ');
      }

      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  bool _isValidResponse(String result) {
    return result.startsWith('data:') ||
        result.startsWith('stream:') ||
        result.startsWith('error:') ||
        (result.startsWith('@') && result.endsWith('@'));
  }

  @visibleForTesting
  Duration? delayBeforeClose;

  @visibleForTesting
  Future<void> closeConnection() async {
    if (delayBeforeClose != null) {
      await Future.delayed(delayBeforeClose!);
    }
    await _connection.close();
  }
}
