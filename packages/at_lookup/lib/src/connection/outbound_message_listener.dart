import 'dart:collection';
import 'dart:convert';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_utils/at_logger.dart';
import 'package:meta/meta.dart';

///Listener class for messages received by [RemoteSecondary]
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

  /// Listens to the underlying connection's socket if the connection is created.
  /// @throws [AtConnectException] if the connection is not yet created
  void listen() {
    _connection.getSocket().listen(messageHandler,
        onDone: _finishedHandler, onError: _errorHandler);
  }

  /// Handles messages on the inbound client's connection and calls the verb executor
  /// Closes the inbound connection in case of any error.
  /// Throw a [BufferOverFlowException] if buffer is unable to hold incoming data
  Future<void> messageHandler(List data) async {
    String result;
    int offset;
    _lastReceivedTime = DateTime.now();
    // check buffer overflow
    _checkBufferOverFlow(data);
    // If the data contains a new line character, add until the new line char to buffer
    if (data.contains(newLineCodeUnit)) {
      offset = data.lastIndexOf(newLineCodeUnit);
      var dataSubList = data.getRange(0, offset).toList();
      _buffer.append(dataSubList);
    } else {
      offset = 0;
    }
    // Loop from last index to until the end of data.
    // If a new line character and followed by @ character is found, then it is end
    // of server response. process the data.
    // Else add the byte to buffer.
    for (int element = offset; element < data.length; element++) {
      // If element is @ character and lastCharacter in the buffer is \n,
      // then complete data is received. process it.
      if (data[element] == atCharCodeUnit &&
          (_buffer.length() > 0 && _buffer.getData().last == newLineCodeUnit)) {
        // remove the terminating character (last \n) from the server response.
        // preserve other new line characters.
        List<int> temp = (_buffer.getData().toList())..removeLast();
        result = utf8.decode(temp);
        result = _stripPrompt(result);
        logger.finer('RECEIVED $result');
        _queue.add(result);
        //clear the buffer after adding result to queue
        _buffer.clear();
        _buffer.addByte(data[element]);
      } else {
        _buffer.addByte(data[element]);
      }
    }
  }

  /// The methods verifies if buffer has the capacity to accept the data.
  ///
  /// Throw BufferOverFlowException if data length exceeds the buffer capacity
  _checkBufferOverFlow(data) {
    if (_buffer.isOverFlow(data)) {
      int bufferLength = (_buffer.length() + data.length) as int;
      _buffer.clear();
      throw BufferOverFlowException(
          'data length exceeded the buffer limit. Data length : $bufferLength and Buffer capacity ${_buffer.capacity}');
    }
  }

  /// The method accepts the result (server response) and trim's the prompt from the response
  /// and returns the actual response.
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

  /// Reads the response sent by remote socket from the queue.
  /// If there is no message in queue after [maxWaitMilliSeconds], return null. Defaults to 90 seconds.
  /// Whenever data is received on client socket from server, [_lastReceivedTime] will be updated to current time.
  /// [transientWaitTimeMillis] specifies the max duration to wait between current time and [_lastReceivedTime] before timing out.Defaults to 10 seconds.
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
        // result from another secondary is either data or a @<atSign>@ denoting complete
        // of the handshake
        if (_isValidResponse(result)) {
          return result;
        }
        //ignore any other response
        _buffer.clear();
        throw AtLookUpException('AT0014', 'Unexpected response found');
      }

      // if currentTime - startTime  is greater than maxWaitMillis throw AtTimeoutException
      if (DateTime.now().difference(startTime).inMilliseconds >
          maxWaitMilliSeconds) {
        _buffer.clear();
        _closeConnection();
        throw AtTimeoutException(
            'Full response not received after $maxWaitMilliSeconds millis from remote secondary');
      }
      // if no data is received from server and if currentTime - _lastReceivedTime is greater than
      // transientWaitTimeMillis throw AtTimeoutException
      if (DateTime.now().difference(_lastReceivedTime).inMilliseconds >
          transientWaitTimeMillis) {
        _buffer.clear();
        _closeConnection();
        throw AtTimeoutException(
            'Waited for $transientWaitTimeMillis millis. No response after $_lastReceivedTime ');
      }
      // wait for 10 ms before attempting to read from queue again
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  bool _isValidResponse(String result) {
    return result.startsWith('data:') ||
        result.startsWith('stream:') ||
        result.startsWith('error:') ||
        (result.startsWith('@') && result.endsWith('@'));
  }

  /// Logs the error and closes the [RemoteSecondary]
  Future<void> _errorHandler(error) async {
    await _closeConnection();
  }

  /// Closes the [OutboundConnection]
  void _finishedHandler() async {
    logger.finest('outbound finish handler called');
    await _closeConnection();
  }

  @visibleForTesting
  Duration? delayBeforeClose;

  Future<void> _closeConnection() async {
    logger.info("_closeConnection() called : isInValid currently ${_connection.isInValid()}");
    if (!_connection.isInValid()) {
      if (delayBeforeClose != null) {
        await Future.delayed(delayBeforeClose!);
      }
      await _connection.close();
    }
  }
}
