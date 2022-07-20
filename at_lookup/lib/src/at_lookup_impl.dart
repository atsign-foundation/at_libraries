import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_message_listener.dart';
import 'package:at_lookup/src/util/lookup_util.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:crypton/crypton.dart';
import 'package:mutex/mutex.dart';

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

  var cramSecret;

  var outboundConnectionTimeout;

  AtLookupImpl(String atSign, String rootDomain, int rootPort,
      {String? privateKey, String? cramSecret}) {
    _currentAtSign = atSign;
    _rootDomain = rootDomain;
    _rootPort = rootPort;
    this.privateKey = privateKey;
    this.cramSecret = cramSecret;
  }

  @Deprecated('use CacheableSecondaryAddressFinder')
  static Future<String?> findSecondary(
      String atsign, String? rootDomain, int rootPort) async {
    // temporary change to preserve backward compatibility and change the callers later on to use
    // SecondaryAddressFinder.findSecondary
    return (await CacheableSecondaryAddressFinder(rootDomain!, rootPort)
            .findSecondary(atsign))
        .toString();
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
    return deleteResult.isNotEmpty; //replace with call back
  }

  @override
  Future<String> llookup(String key,
      {String? sharedBy, String? sharedWith, bool isPublic = false}) async {
    LLookupVerbBuilder builder;
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
    if (verifyData == false) {
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
      logger.finer('value: $value dataSignature:$dataSignature');
      var isDataValid = publicKey.verifySHA256Signature(
          utf8.encode(value) as Uint8List, base64Decode(dataSignature));
      logger.finer('atlookup data verify result: $isDataValid');
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
      {String? regex,
      String? sharedBy,
      bool auth = true,
      bool showHiddenKeys = false}) async {
    var builder = ScanVerbBuilder()
      ..sharedBy = sharedBy
      ..regex = regex
      ..auth = auth
      ..showHiddenKeys = showHiddenKeys;
    var scanResult = await executeVerb(builder);
    if (scanResult.isNotEmpty) {
      scanResult = scanResult.replaceFirst('data:', '');
    }
    return (scanResult.isNotEmpty) ? List.from(jsonDecode(scanResult)) : [];
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
    return putResult.isNotEmpty;
  }

  Future<void> createConnection() async {
    if (!isConnectionAvailable()) {
      logger.info('Creating new connection');
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
      await createOutBoundConnection(host, port, _currentAtSign);
      //3. listen to server response
      messageListener = OutboundMessageListener(_connection);
      messageListener.listen();
    }
  }

  /// Executes the command returned by [VerbBuilder] build command on a remote secondary server.
  /// Optionally [privateKey] is passed for verb builders which require authentication.
  ///
  /// Catches any exception and throws [AtLookUpException]
  @override
  Future<String> executeVerb(VerbBuilder builder, {sync = false}) async {
    String verbResult = '';
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
      } else if (builder is SyncVerbBuilder) {
        verbResult = await _sync(builder);
      } else if (builder is NotifyRemoveVerbBuilder) {
        verbResult = await _notifyRemove(builder);
      }
    } on Exception catch (e) {
      logger.severe('Error in remote verb execution ${e.toString()}');
      var errorCode = AtLookUpExceptionUtil.getErrorCode(e);
      throw AtLookUpException(errorCode, e.toString());
    }
    // If connection time-out, do not return empty verbResult;
    // throw AtLookupException.
    if (verbResult.isEmpty) {
      throw AtLookUpException('AT0014', 'Request timed out');
    }
    // If response starts with error:, throw AtLookupException.
    if (_isError(verbResult)) {
      verbResult = verbResult.replaceAll('error:', '');
      // Setting the errorCode and errorDescription to default values.
      var errorCode = 'AT0014';
      var errorDescription = 'Unknown server error';
      if (verbResult.contains('-')) {
        if (verbResult.split('-')[0].isNotEmpty) {
          errorCode = verbResult.split('-')[0];
        }
        if (verbResult.split('-')[1].isNotEmpty) {
          errorDescription = verbResult.split('-')[1];
        }
      }
      throw AtLookUpException(errorCode, errorDescription);
    }
    // Return the verb result.
    return verbResult;
  }

  bool _isError(String verbResult) {
    return verbResult.startsWith('error:');
  }

  Future<String> _update(UpdateVerbBuilder builder) async {
    String atCommand;
    if (builder.operation == UPDATE_META) {
      atCommand = builder.buildCommandForMeta();
    } else {
      atCommand = builder.buildCommand();
    }
    logger.finer('update to remote: $atCommand');
    return await _process(atCommand, auth: true);
  }

  Future<String> _notify(NotifyVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    logger.finer('notify to remote: $atCommand');
    return await _process(atCommand, auth: true);
  }

  Future<String> _scan(ScanVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: builder.auth);
  }

  Future<String> _stats(StatsVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String> _config(ConfigVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String> _notifyStatus(NotifyStatusVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String> _notifyList(NotifyListVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String> _notifyAll(NotifyAllVerbBuilder builder) async {
    var command = builder.buildCommand();
    return await _process(command, auth: true);
  }

  Future<String> _notifyRemove(NotifyRemoveVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String> _sync(SyncVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String?> executeCommand(String atCommand, {bool auth = false}) async {
    return await _process(atCommand, auth: auth);
  }

  final Mutex _pkamAuthenticationMutex = Mutex();

  /// Generates digest using from verb response and [privateKey] and performs a PKAM authentication to
  /// secondary server. This method is executed for all verbs that requires authentication.
  Future<bool> authenticate(String? privateKey) async {
    if (privateKey == null) {
      throw UnAuthenticatedException('Private key not passed');
    }
    try {
      _pkamAuthenticationMutex.acquire();
      if (!_isPkamAuthenticated) {
        await _sendCommand('from:$_currentAtSign\n');
        var fromResponse = await (messageListener.read());
        logger.finer('from result:$fromResponse');
        if (fromResponse.isEmpty) {
          return false;
        }
        fromResponse = fromResponse.trim().replaceAll('data:', '');
        logger.finer('fromResponse $fromResponse');
        var key = RSAPrivateKey.fromString(privateKey);
        var sha256signature =
            key.createSHA256Signature(utf8.encode(fromResponse) as Uint8List);
        var signature = base64Encode(sha256signature);
        logger.finer('Sending command pkam:$signature');
        await _sendCommand('pkam:$signature\n');
        var pkamResponse = await messageListener.read();
        if (pkamResponse == 'data:success') {
          logger.info('auth success');
          _isPkamAuthenticated = true;
        } else {
          throw UnAuthenticatedException(
              'Failed connecting to $_currentAtSign. $pkamResponse');
        }
      }
      return _isPkamAuthenticated;
    } finally {
      _pkamAuthenticationMutex.release();
    }
  }

  final Mutex _cramAuthenticationMutex = Mutex();

  /// Generates digest using from verb response and [secret] and performs a CRAM authentication to
  /// secondary server
  Future<bool> authenticate_cram(var secret) async {
    secret ??= cramSecret;
    if (secret == null) {
      throw UnAuthenticatedException('Cram secret not passed');
    }
    try {
      _cramAuthenticationMutex.acquire();
      if (!_isCramAuthenticated) {
        await _sendCommand('from:$_currentAtSign\n');
        var fromResponse = await messageListener.read();
        logger.info('from result:$fromResponse');
        if (fromResponse.isEmpty) {
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
      }
      return _isCramAuthenticated;
    } finally {
      _cramAuthenticationMutex.release();
    }
  }

  Future<String> _plookup(PLookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String> _lookup(LookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: builder.auth);
  }

  Future<String> _llookup(LLookupVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(atCommand, auth: true);
  }

  Future<String> _delete(DeleteVerbBuilder builder) async {
    var atCommand = builder.buildCommand();
    return await _process(
      atCommand,
      auth: true,
    );
  }

  Mutex requestResponseMutex = Mutex();

  Future<String> _process(String command, {bool auth = false}) async {
    try {
      await requestResponseMutex.acquire();

      if (auth && _isAuthRequired()) {
        if (privateKey != null) {
          await authenticate(privateKey);
        } else if (cramSecret != null) {
          await authenticate_cram(cramSecret);
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
    } finally {
      requestResponseMutex.release();
    }
  }

  bool _isAuthRequired() {
    return !isConnectionAvailable() ||
        !(_isPkamAuthenticated || _isCramAuthenticated);
  }

  Future<bool> createOutBoundConnection(host, port, toAtSign) async {
    try {
      var secureSocket = await SecureSocket.connect(host, int.parse(port));
      _connection = OutboundConnectionImpl(secureSocket);
      if (outboundConnectionTimeout != null) {
        _connection!.setIdleTime(outboundConnectionTimeout);
      }
    } on SocketException {
      throw SecondaryConnectException(
          'unable to connect to secondary $toAtSign on $host:$port');
    }
    return true;
  }

  bool isConnectionAvailable() {
    return _connection != null && !_connection!.isInValid();
  }

  bool isInValid() {
    return _connection!.isInValid();
  }

  Future<void> close() async {
    await _connection!.close();
  }

  Future<void> _sendCommand(String command) async {
    await createConnection();
    logger.finer('SENDING: $command');
    await _connection!.write(command);
  }
}
