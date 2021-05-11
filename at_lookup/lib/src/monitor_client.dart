import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_connection.dart';
import 'package:at_lookup/src/connection/outbound_connection_impl.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';

/// Utility class to execute monitor verb.
class MonitorClient {
  final _monitorVerbResponseQueue = Queue();
  var response;
  late var _privateKey;
  var logger = AtSignLogger('MonitorVerbManager');

  MonitorClient(String privateKey) {
    _privateKey = privateKey;
  }

  ///Monitor Verb
  Future<OutboundConnection> executeMonitorVerb(String _command, String _atSign,
      String _rootDomain, int _rootPort, Function notificationCallBack,
      {bool auth = true, Function? restartCallBack}) async {
    //1. Get a new outbound connection dedicated to monitor verb.
    logger.finer('before monitor create connection');
    var _monitorConnection =
        await _createNewConnection(_atSign, _rootDomain, _rootPort);
    logger.finer('after monitor create connection');
    //2. Listener on _monitorConnection.
    _monitorConnection.getSocket().listen((event) {
      response = utf8.decode(event);
      // If response contains data to be notified, invoke callback function.
      if (response.toString().startsWith('notification')) {
        notificationCallBack(response);
      } else {
        _monitorVerbResponseQueue.add(response);
      }
    }, onError: (error) {
      _errorHandler(error, _monitorConnection);
    }, onDone: () {
      _finishedHandler(_monitorConnection);
      restartCallBack!(_command, notificationCallBack, _privateKey);
    });
    await _authenticateConnection(_atSign, _monitorConnection);
    //3. Write monitor verb to connection
    await _monitorConnection.write(_command);
    return _monitorConnection;
  }

  /// Create a new connection for monitor verb.
  Future<OutboundConnection> _createNewConnection(
      String toAtSign, String rootDomain, int rootPort) async {
    //1. find secondary url for atsign from lookup library
    var secondaryUrl =
        await AtLookupImpl.findSecondary(toAtSign, rootDomain, rootPort);
    var secondaryInfo = _getSecondaryInfo(secondaryUrl);
    var host = secondaryInfo[0];
    var port = secondaryInfo[1];

    //2. create a connection to secondary server
    var secureSocket = await SecureSocket.connect(host, int.parse(port));
    OutboundConnection _monitorConnection =
        OutboundConnectionImpl(secureSocket);
    return _monitorConnection;
  }

  /// To authenticate connection via PKAM verb.
  Future<OutboundConnection> _authenticateConnection(
      String _atSign, OutboundConnection _monitorConnection) async {
    await _monitorConnection.write('from:$_atSign\n');
    var fromResponse = await _getQueueResponse();
    logger.info('from result:$fromResponse');
    fromResponse = fromResponse.trim().replaceAll('data:', '');
    logger.info('fromResponse $fromResponse');
    var key = RSAPrivateKey.fromString(_privateKey);
    var sha256signature =
        key.createSHA256Signature(utf8.encode(fromResponse) as Uint8List);
    var signature = base64Encode(sha256signature);
    logger.info('Sending command pkam:$signature');
    await _monitorConnection.write('pkam:$signature\n');
    var pkamResponse = await _getQueueResponse();
    if (pkamResponse == null || !pkamResponse.contains('success')) {
      throw UnAuthenticatedException('Auth failed');
    }
    logger.info('auth success');
    return _monitorConnection;
  }

  ///Returns the response of the monitor verb queue.
  Future<String> _getQueueResponse() async {
    var maxWaitMilliSeconds = 5000;
    var result = '';
    //wait maxWaitMilliSeconds seconds for response from remote socket
    var loopCount = (maxWaitMilliSeconds / 50).round();
    for (var i = 0; i < loopCount; i++) {
      await Future.delayed(Duration(milliseconds: 90));
      var queueLength = _monitorVerbResponseQueue.length;
      if (queueLength > 0) {
        result = _monitorVerbResponseQueue.removeFirst();
        // result from another secondary is either data or a @<atSign>@ denoting complete
        // of the handshake
        if (result.startsWith('data:')) {
          var index = result.indexOf(':');
          result = result.substring(index + 1, result.length - 2);
          break;
        }
      }
    }
    return result;
  }

  List<String> _getSecondaryInfo(String? url) {
    var result = <String>[];
    if (url != null && url.contains(':')) {
      var arr = url.split(':');
      result.add(arr[0]);
      result.add(arr[1]);
    }
    return result;
  }

  /// Logs the error and closes the [OutboundConnection]
  void _errorHandler(error, OutboundConnection _connection) async {
    await _closeConnection(_connection);
  }

  /// Closes the [OutboundConnection]
  void _finishedHandler(OutboundConnection _connection) async {
    await _closeConnection(_connection);
  }

  Future<void> _closeConnection(OutboundConnection _connection) async {
    if (!_connection.isInValid()) {
      await _connection.close();
    }
  }
}
