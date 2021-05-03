import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/at_constants.dart' as at_constants;
import 'package:at_lookup/src/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_connection.dart';
import 'package:at_lookup/src/connection/outbound_connection_impl.dart';
import 'package:at_lookup/src/connection/outbound_message_listener.dart';
import 'package:at_lookup/src/exception/at_lookup_exception.dart';
import 'package:at_lookup/src/util/lookup_util.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:crypton/crypton.dart';

class AtLookupImpl implements AtLookUp {
  final logger = AtSignLogger('AtLookup');

  /// Listener for reading verb responses from the remote server
  late OutboundMessageListener messageListener;

  bool _isPkamAuthenticated = false;

  bool _isCramAuthenticated = false;

  OutboundConnection? _connection;

  OutboundConnection? get connection => _connection;

  var _currentAtSign;

  var _rootDomain;

  late var _rootPort;

  var privateKey;

  var _cramSecret;

  var outboundConnectionTimeout;

  AtLookupImpl(
    String atSign,
    String rootDomain,
    int rootPort, {
    String? privateKey,
    String? cramSecret,
  }) {
    _currentAtSign = atSign;
    _rootDomain = rootDomain;
    _rootPort = rootPort;
    this.privateKey = privateKey;
    _cramSecret = cramSecret;
  }

  static Future<String?> findSecondary(
      String atsign, String? rootDomain, int rootPort) async {
    String? response;
    SecureSocket? socket;
    try {
      AtSignLogger('AtLookup')
          .finer('AtLookup.findSecondary received atsign: $atsign');
      if (atsign.startsWith('@')) atsign = atsign.replaceFirst('@', '');
      var answer = '';
      String? secondary;
      var ans = false;
      var prompt = false;
      var once = true;
      // ignore: omit_local_variable_types
      socket = await SecureSocket.connect(rootDomain, rootPort);
      // listen to the received data event stream
      socket.listen((List<int> event) async {
        answer = utf8.decode(event);

        if (answer.endsWith('@') && prompt == false && once == true) {
          prompt = true;
          socket!.write('$atsign\n');
          await socket.flush();
          once = false;
        }

        if (answer.contains(':')) {
          answer = answer.replaceFirst('\r\n@', '');
          answer = answer.replaceFirst('@', '');
          answer = answer.replaceAll('@', '');
          secondary = answer.trim();
          ans = true;
        } else if (answer.startsWith('null')) {
          secondary = null;
          ans = true;
        }
      });
      // wait 5 seconds
      for (var i = 0; i < 100; i++) {
        await Future.delayed(Duration(milliseconds: 50));
        if (ans) {
          response = secondary;
          socket.write('@exit\n');
          await socket.flush();
          socket.destroy();
          AtSignLogger('AtLookup').finer(
              'AtLookup.findSecondary got answer: $secondary and closing connection');
          return response;
        }
      }
      // .. and close the socket
      await socket.flush();
      socket.destroy();
      throw Exception('AtLookup.findSecondary timed out');
    } on Exception catch (exception) {
      AtSignLogger('AtLookup').severe('AtLookup.findSecondary connection to ' +
          rootDomain! +
          ' exception: ' +
          exception.toString());
      if (socket != null) {
        socket.destroy();
      }
    } catch (error) {
      AtSignLogger('AtLookup').severe(
          'AtLookup.findSecondary connection to root server failed with error: $error');
      if (socket != null) {
        socket.destroy();
      }
    }
    return response;
  }

  @override
  Future<bool> delete(String key,
      {String? sharedWith, bool isPublic = false}) async {
    var builder = DeleteVerbBuilder()
      ..isPublic = isPublic
      ..sharedWith = sharedWith
      ..atKey = key
      ..sharedBy = _currentAtSign;
    var deleteResult = await executeVerb(builder);
    return deleteResult != null; //replace with call back
  }

  @override
  Future<String> llookup(String key,
      {String? sharedBy, String? sharedWith, bool isPublic = false}) async {
    var builder;
    if (sharedWith != null) {
      builder = LLookupVerbBuilder()
        ..isPublic = isPublic
        ..sharedWith = sharedWith
        ..atKey = key
        ..sharedBy = _currentAtSign;
    } else if (isPublic && sharedBy == null && sharedWith == null) {
      builder = LLookupVerbBuilder()
        ..atKey = 'public:' + key
        ..sharedBy = _currentAtSign;
    } else {
      builder = LLookupVerbBuilder()
        ..atKey = key
        ..sharedBy = _currentAtSign;
    }
    var llookupResult = await executeVerb(builder);
    llookupResult = VerbUtil.getFormattedValue(llookupResult);
    return llookupResult;
  }

  @override
  Future<String> lookup(String key, String sharedBy,
      {bool auth = true,
      bool verifyData = false,
      bool metadata = false}) async {
    var builder = LookupVerbBuilder()
      ..atKey = key
      ..sharedBy = sharedBy
      ..auth = auth
      ..operation = metadata == true ? 'all' : null;
    if (verifyData == null || verifyData == false) {
      var lookupResult = await executeVerb(builder);
      lookupResult = VerbUtil.getFormattedValue(lookupResult);
      return lookupResult;
    }
    //verify data signature if verifyData is set to true
    try {
      builder = LookupVerbBuilder()
        ..atKey = key
        ..sharedBy = sharedBy
        ..auth = false
        ..operation = 'all';
      String? lookupResult = await executeVerb(builder);
      lookupResult = lookupResult.replaceFirst('data:', '');
      var resultJson = json.decode(lookupResult);
      logger.finer(resultJson);

      String? publicKeyResult = '';
      if (auth) {
        publicKeyResult = await plookup('publickey', sharedBy);
      } else {
        var publicKeyLookUpBuilder = LookupVerbBuilder()
          ..atKey = 'publickey'
          ..sharedBy = sharedBy;
        publicKeyResult = await executeVerb(publicKeyLookUpBuilder);
      }
      publicKeyResult = publicKeyResult.replaceFirst('data:', '');
      logger.finer('public key of $sharedBy :$publicKeyResult');

      var publicKey = RSAPublicKey.fromString(publicKeyResult);
      var dataSignature = resultJson['metaData']['dataSignature'];
      var value = resultJson['data'];
      value = VerbUtil.getFormattedValue(value);
      logger.finer('value: ${value} dataSignature:${dataSignature}');
      var isDataValid = publicKey.verifySHA256Signature(
          utf8.encode(value) as Uint8List, base64Decode(dataSignature));
      logger.finer('atlookup data verify result: ${isDataValid}');
      return 'data:$value';
    } on Exception catch (e) {
      logger.severe(
          'Error while verify public data for key: $key sharedBy: $sharedBy exception:${e.toString()}');
      return 'data:null';
    }
  }

  @override
  Future<String> plookup(String key, String sharedBy) async {
    var builder = PLookupVerbBuilder()
      ..atKey = key
      ..sharedBy = sharedBy;
    var plookupResult = await executeVerb(builder);
    plookupResult = VerbUtil.getFormattedValue(plookupResult);
    return plookupResult;
  }

  @override
  Future<List<String>> scan(
      {String? regex, String? sharedBy, bool auth = true}) async {
    var builder = ScanVerbBuilder()
      ..sharedBy = sharedBy
      ..regex = regex
      ..auth = auth;
    var scanResult = await executeVerb(builder);
    if (scanResult != null) {
      scanResult = scanResult.replaceFirst('data:', '');
    }
    return (scanResult != null && scanResult.isNotEmpty)
        ? List.from(jsonDecode(scanResult))
        : [];
  }

  @override
  Future<bool> update(String key, String value,
      {String? sharedWith, Metadata? metadata}) async {
    var builder = UpdateVerbBuilder()
      ..atKey = key
      ..sharedBy = _currentAtSign
      ..sharedWith = sharedWith
      ..value = value;
    if (metadata != null) {
      builder.ttl = metadata.ttl;
      builder.ttb = metadata.ttb;
      builder.ttr = metadata.ttr;
      builder.isPublic = metadata.isPublic!;
      if (metadata.isHidden) {
        builder.atKey = '_' + key;
      }
    }
    var putResult = await executeVerb(builder);
    return putResult != null;
  }

  Future<void> _createConnection() async {
    if (!_isConnectionAvailable()) {
      //1. find secondary url for atsign from lookup library
      var secondaryUrl =
          await findSecondary(_currentAtSign, _rootDomain, _rootPort);
      if (secondaryUrl == null) {
        throw SecondaryNotFoundException('Secondary server not found');
      }
      var secondaryInfo = LookUpUtil.getSecondaryInfo(secondaryUrl);
      var host = secondaryInfo[0];
      var port = secondaryInfo[1];
      //2. create a connection to secondary server
      await _createOutBoundConnection(host, port, _currentAtSign);
      //3. listen to server response
      messageListener = OutboundMessageListener(_connection);
      messageListener.listen();
    }
  }

  /// Executes the command returned by [VerbBuilder] build command on a remote secondary server.
  /// Optionally [privateKey] is passed for verb builders which require authentication.
  @override
  Future<String> executeVerb(VerbBuilder builder, {sync = false}) async {
    late var verbResult;
    try {
      if (builder is UpdateVerbBuilder) {
        verbResult = await _update(builder);
      } else if (builder is DeleteVerbBuilder) {
        verbResult = await _delete(builder);
      } else if (builder is LookupVerbBuilder) {
        verbResult = await _lookup(builder);
      } else if (builder is LLookupVerbBuilder) {
        verbResult = await _llookup(builder);
      } else if (builder is PLookupVerbBuilder) {
        verbResult = await _plookup(builder);
      } else if (builder is ScanVerbBuilder) {
        verbResult = await _scan(builder);
      } else if (builder is StatsVerbBuilder) {
        verbResult = await _stats(builder);
      } else if (builder is ConfigVerbBuilder) {
        verbResult = await _config(builder);
      } else if (builder is NotifyVerbBuilder) {
        verbResult = await _notify(builder);
      } else if (builder is NotifyStatusVerbBuilder) {
        verbResult = await _notifyStatus(builder);
      } else if (builder is NotifyListVerbBuilder) {
        verbResult = await _notifyList(builder);
      } else if (builder is NotifyAllVerbBuilder) {
        verbResult = await _notifyAll(builder);
      }
    } on Exception catch (e) {
      logger.severe('Error in remote verb execution ${e.toString()}');
      var errorCode = AtLookUpExceptionUtil.getErrorCode(e);
      return Future.error(AtLookUpException(
          errorCode, AtLookUpExceptionUtil.getErrorDescription(errorCode)));
    }
    if (_isError(verbResult)) {
      verbResult = verbResult.replaceAll('error:', '');
      var errorCode = verbResult.split('-')[0];
      var errorMessage = verbResult.split('-')[1];
      return Future.error(AtLookUpException(errorCode, errorMessage));
    }
    return verbResult;
  }

  bool _isError(String? verbResult) {
    return verbResult != null && verbResult.startsWith('error:');
  }

  Future<String?> _update(UpdateVerbBuilder builder) async {
    var atCommand;
    if (builder.operation == at_constants.UPDATE_META) {
      atCommand = builder.buildCommandForMeta();
    } else {
      atCommand = builder.buildCommand();
    }
    logger.finer('update to remote: ${atCommand}');
    return await _process(atCommand, auth: true);
  }

  Future<String?> _notify(NotifyVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    logger.finer('notify to remote: ${atCommand}');
    return await _process(atCommand, auth: true);
  }

  Future<String?> _scan(ScanVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: builder.auth);
  }

  Future<String?> _stats(StatsVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String?> _config(ConfigVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String?> _notifyStatus(NotifyStatusVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String?> _notifyList(NotifyListVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String?> _notifyAll(NotifyAllVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String?> executeCommand(String atCommand, {bool auth = false}) async {
    return await _process(atCommand, auth: auth);
  }

  /// Generates digest using from verb response and [privateKey] and performs a PKAM authentication to
  /// secondary server. This method is executed for all verbs that requires authentication.
  Future<bool> authenticate(String? privateKey) async {
    if (privateKey == null) {
      throw UnAuthenticatedException('Private key not passed');
    }
    await _sendCommand('from:$_currentAtSign\n');
    var fromResponse = await (messageListener.read() as FutureOr<String>);
    logger.finer('from result:${fromResponse}');
    fromResponse = fromResponse.trim().replaceAll('data:', '');
    logger.finer('fromResponse $fromResponse');
    var key = RSAPrivateKey.fromString(privateKey);
    var sha256signature = key.createSHA256Signature(utf8.encode(fromResponse) as Uint8List);
    var signature = base64Encode(sha256signature);
    logger.finer('Sending command pkam:$signature');
    await _sendCommand('pkam:$signature\n');
    var pkamResponse = await messageListener.read();
    if (pkamResponse == 'data:success') {
      logger.info('auth success');
      _isPkamAuthenticated = true;
    } else {
      throw UnAuthenticatedException('Auth failed');
    }
    return _isPkamAuthenticated;
  }

  /// Generates digest using from verb response and [secret] and performs a CRAM authentication to
  /// secondary server
  Future<bool> authenticate_cram(var secret) async {
    secret ??= _cramSecret;
    if (secret == null) {
      throw UnAuthenticatedException('Cram secret not passed');
    }
    await _sendCommand('from:$_currentAtSign\n');
    var fromResponse = await messageListener.read();
    logger.info('from result:$fromResponse');
    if (fromResponse == null) {
      return false;
    }
    fromResponse = fromResponse.trim().replaceAll('data:', '');
    var digestInput = '$secret$fromResponse';
    var bytes = utf8.encode(digestInput);
    var digest = sha512.convert(bytes);
    await _sendCommand('cram:$digest\n');
    var cramResponse = await messageListener.read();
    if (cramResponse == 'data:success') {
      logger.info('auth success');
      _isCramAuthenticated = true;
    } else {
      throw UnAuthenticatedException('Auth failed');
    }
    return _isCramAuthenticated;
  }

  Future<String?> _plookup(PLookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String?> _lookup(LookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: builder.auth);
  }

  Future<String?> _llookup(LLookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String?> _delete(DeleteVerbBuilder builder, {String? privateKey}) async {
    var atCommand = builder.buildCommand();
    return await _process(
      atCommand,
      auth: true,
    );
  }

  Future<String?> _process(String command, {bool auth = false}) async {
    if (auth != null && auth && _isAuthRequired()) {
      if (privateKey != null) {
        await authenticate(privateKey);
      } else if (_cramSecret != null) {
        await authenticate_cram(_cramSecret);
      } else {
        throw UnAuthenticatedException(
            'Unable to perform atlookup auth. Private key/cram secret is not set');
      }
    }
    try {
      await _sendCommand(command);
      var result = await messageListener.read();
      return result;
    } on Exception catch (e) {
      logger.severe('Exception in sending to server, ${e.toString()}');
      rethrow;
    }
  }

  bool _isAuthRequired() {
    return !_isConnectionAvailable() ||
        !(_isPkamAuthenticated || _isCramAuthenticated);
  }

  Future<bool> _createOutBoundConnection(host, port, toAtSign) async {
    try {
      var secureSocket = await SecureSocket.connect(host, int.parse(port));
      _connection = OutboundConnectionImpl(secureSocket);
      if (outboundConnectionTimeout != null) {
        _connection!.setIdleTime(outboundConnectionTimeout);
      }
    } on SocketException {
      throw SecondaryConnectException('unable to connect to secondary');
    }
    return true;
  }

  bool _isConnectionAvailable() {
    return _connection != null && !_connection!.isInValid();
  }

  bool isInValid() {
    return _connection!.isInValid();
  }

  Future<void> close() async {
    await _connection!.close();
  }

  Future<void> _sendCommand(String command) async {
    await _createConnection();
    await _connection!.write(command);
  }
}
