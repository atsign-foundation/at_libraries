// ignore_for_file: unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_message_listener.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypto/crypto.dart';
import 'package:crypton/crypton.dart';
import 'package:mutex/mutex.dart';
import 'package:at_chops/at_chops.dart';

class AtLookupImpl implements AtLookUp {
  late final AtSignLogger logger;

  /// Listener for reading verb responses from the remote server
  late OutboundMessageListener messageListener;

  OutboundConnection? _connection;

  OutboundConnection? get connection => _connection;

  @override
  late SecondaryAddressFinder secondaryAddressFinder;

  late String _currentAtSign;

  late String _rootDomain;

  late int _rootPort;

  String? privateKey;

  String? cramSecret;

  // ignore: prefer_typing_uninitialized_variables
  var outboundConnectionTimeout;

  late SecureSocketConfig _secureSocketConfig;

  /// Represents the client configurations.
  late Map<String, dynamic> _clientConfig;

  AtChops? _atChops;

  Duration? socketConnectTimeout;

  Duration defaultSocketConnectTimeout = Duration(seconds: 10);

  String? _serverNetworkSessionId;
  String? get serverNetworkSessionId => _serverNetworkSessionId;

  AtLookupImpl(String atSign, String rootDomain, int rootPort,
      {this.privateKey,
      this.cramSecret,
      SecondaryAddressFinder? secondaryAddressFinder,
      SecureSocketConfig? secureSocketConfig,
      Map<String, dynamic>? clientConfig,
      this.socketConnectTimeout}) {
    _currentAtSign = atSign;
    logger = AtSignLogger('AtLookup ($_currentAtSign)');
    _rootDomain = rootDomain;
    _rootPort = rootPort;
    this.secondaryAddressFinder = secondaryAddressFinder ??
        CacheableSecondaryAddressFinder(rootDomain, rootPort);
    _secureSocketConfig = secureSocketConfig ?? SecureSocketConfig();
    // Stores the client configurations.
    // If client configurations are not available, defaults to empty map
    _clientConfig = clientConfig ?? {};
    socketConnectTimeout ??= defaultSocketConnectTimeout;
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
      logger.finer('atLookup data verify result: $isDataValid');
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
    //checks for network availability. Throws AtConnectException when unavailable
    await networkAvailabilityCheck();

    if (!isConnectionAvailable()) {
      logger.info('Creating new connection');

      //1. find secondary url for atsign from lookup library
      logger.info('  Finding secondary address');
      SecondaryAddress secondaryAddress =
          await secondaryAddressFinder.findSecondary(_currentAtSign);
      var host = secondaryAddress.host;
      var port = secondaryAddress.port;

      //2. create a connection to secondary server
      logger.info('  Creating outbound connection to $secondaryAddress');
      await createOutBoundConnection(
          host, port.toString(), _currentAtSign, _secureSocketConfig);

      //3. set up listener to handle responses
      logger.info('  Starting listener for outbound connection');
      messageListener = OutboundMessageListener(_connection!);
      messageListener.listen();
      logger.info('New connection created OK');
    }
  }

  /// Executes the command returned by [VerbBuilder] build command on a remote secondary server.
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
      } else if (builder is NotifyFetchVerbBuilder) {
        verbResult = await _notifyFetch(builder);
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
      try {
        var errorMap = jsonDecode(verbResult);
        errorCode = errorMap['errorCode'];
        errorDescription = errorMap['errorDescription'];
      } on FormatException {
        // Catching the FormatException to preserve backward compatibility - responses without jsonEncoding.
        // TODO: Can we remove the below catch block in next release once all the servers are migrated to new version.
        if (verbResult.contains('-')) {
          if (verbResult.split('-')[0].isNotEmpty) {
            errorCode = verbResult.split('-')[0];
          }
          if (verbResult.split('-')[1].isNotEmpty) {
            errorDescription = verbResult.split('-')[1];
          }
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

  Future<String> _notifyFetch(NotifyFetchVerbBuilder builder) async {
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
  /// @Deprecated('Use method pkamAuthenticate') Commenting deprecation since it causes issue in dart analyze in the caller
  Future<bool> authenticate(String? privateKey) async {
    if (privateKey == null) {
      throw UnAuthenticatedException('Private key not passed');
    }
    await createConnection();
    try {
      await _pkamAuthenticationMutex.acquire();
      if (!_connection!.getMetaData()!.isAuthenticated) {
        await _sendCommand((FromVerbBuilder()
              ..atSign = _currentAtSign
              ..clientConfig = _clientConfig)
            .buildCommand());
        var fromResponse = await (messageListener.read(
            transientWaitTimeMillis: 5000, maxWaitMilliSeconds: 10000));
        logger.finer('from result:$fromResponse');
        if (fromResponse.isEmpty) {
          return false;
        }

        // The fromResponse looks like data:<serverNetworkSessionId>@<atsign>:<random stuff>
        fromResponse = fromResponse.trim().replaceAll('data:', '');
        logger.finer('fromResponse $fromResponse');

        _serverNetworkSessionId = fromResponse.split('@')[0];
        messageListener.serverNetworkSessionId = _serverNetworkSessionId;

        var key = RSAPrivateKey.fromString(privateKey);
        var sha256signature =
            key.createSHA256Signature(utf8.encode(fromResponse) as Uint8List);
        var signature = base64Encode(sha256signature);
        logger.finer('Sending command pkam:$signature');
        await _sendCommand('pkam:$signature\n');
        var pkamResponse = await messageListener.read(
            transientWaitTimeMillis: 5000, maxWaitMilliSeconds: 10000);
        if (pkamResponse == 'data:success') {
          logger.info('auth success');
          _connection!.getMetaData()!.isAuthenticated = true;
        } else {
          throw UnAuthenticatedException(
              'Failed connecting to $_currentAtSign. $pkamResponse');
        }
      }
      return _connection!.getMetaData()!.isAuthenticated;
    } finally {
      _pkamAuthenticationMutex.release();
    }
  }

  @override
  Future<bool> pkamAuthenticate() async {
    await createConnection();
    try {
      await _pkamAuthenticationMutex.acquire();
      if (!_connection!.getMetaData()!.isAuthenticated) {
        await _sendCommand((FromVerbBuilder()
              ..atSign = _currentAtSign
              ..clientConfig = _clientConfig)
            .buildCommand());
        var fromResponse = await (messageListener.read(
            transientWaitTimeMillis: 5000, maxWaitMilliSeconds: 10000));
        logger.finer('from result:$fromResponse');
        if (fromResponse.isEmpty) {
          return false;
        }
        // The fromResponse looks like data:<serverNetworkSessionId>@<atsign>:<random stuff>
        fromResponse = fromResponse.trim().replaceAll('data:', '');
        logger.finer('fromResponse $fromResponse');

        _serverNetworkSessionId = fromResponse.split('@')[0];
        messageListener.serverNetworkSessionId = _serverNetworkSessionId;

        var signingResult =
            _atChops!.signString(fromResponse, SigningKeyType.pkamSha256);
        logger.finer('Sending command pkam:${signingResult.result}');
        await _sendCommand('pkam:${signingResult.result}\n');
        var pkamResponse = await messageListener.read(
            transientWaitTimeMillis: 5000, maxWaitMilliSeconds: 10000);
        if (pkamResponse == 'data:success') {
          logger.info('auth success');
          _connection!.getMetaData()!.isAuthenticated = true;
        } else {
          throw UnAuthenticatedException(
              'Failed connecting to $_currentAtSign. $pkamResponse');
        }
      }
      return _connection!.getMetaData()!.isAuthenticated;
    } finally {
      _pkamAuthenticationMutex.release();
    }
  }

  final Mutex _cramAuthenticationMutex = Mutex();

  /// Generates digest using from verb response and [secret] and performs a CRAM authentication to
  /// secondary server
  // ignore: non_constant_identifier_names
  Future<bool> authenticate_cram(var secret) async {
    secret ??= cramSecret;
    if (secret == null) {
      throw UnAuthenticatedException('Cram secret not passed');
    }
    await createConnection();
    try {
      await _cramAuthenticationMutex.acquire();
      if (!_connection!.getMetaData()!.isAuthenticated) {
        await _sendCommand((FromVerbBuilder()
              ..atSign = _currentAtSign
              ..clientConfig = _clientConfig)
            .buildCommand());
        var fromResponse = await messageListener.read(
            transientWaitTimeMillis: 4000, maxWaitMilliSeconds: 10000);
        logger.info('from result:$fromResponse');
        if (fromResponse.isEmpty) {
          return false;
        }
        fromResponse = fromResponse.trim().replaceAll('data:', '');
        var digestInput = '$secret$fromResponse';
        var bytes = utf8.encode(digestInput);
        var digest = sha512.convert(bytes);
        await _sendCommand('cram:$digest\n');
        var cramResponse = await messageListener.read(
            transientWaitTimeMillis: 4000, maxWaitMilliSeconds: 10000);
        if (cramResponse == 'data:success') {
          logger.info('auth success');
          _connection!.getMetaData()!.isAuthenticated = true;
        } else {
          throw UnAuthenticatedException('Auth failed');
        }
      }
      return _connection!.getMetaData()!.isAuthenticated;
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

  /// Ensures that a new request isn't sent until either response has been received from previous
  /// request, or response wasn't received due to timeout or other exception
  Mutex requestResponseMutex = Mutex();

  Future<String> _process(String command, {bool auth = false}) async {
    try {
      await requestResponseMutex.acquire();

      if (auth && _isAuthRequired()) {
        if (_atChops != null) {
          logger.finer('Using AtChops to do the PKAM signing');
          await pkamAuthenticate();
        } else if (privateKey != null) {
          logger.finer('NOT using atChops to do the PKAM signing');
          await authenticate(privateKey);
        } else if (cramSecret != null) {
          await authenticate_cram(cramSecret);
        } else {
          throw UnAuthenticatedException(
              'Unable to perform atLookup auth. Private key/cram secret is not set');
        }
      }
      try {
        await _sendCommand(command);
      } on Exception catch (e) {
        logger.severe('Exception while sending to server - ${e.toString()}');
        rethrow;
      }
      try {
        var result = await messageListener.read();
        return result;
      } on Exception catch (e) {
        logger
            .severe('Exception while getting server response - ${e.toString()}');
        rethrow;
      }
    } finally {
      requestResponseMutex.release();
    }
  }

  bool _isAuthRequired() {
    return !isConnectionAvailable() ||
        !(_connection!.getMetaData()!.isAuthenticated);
  }

  Future<bool> createOutBoundConnection(String host, String port,
      String toAtSign, SecureSocketConfig secureSocketConfig) async {
    try {
      logger.info('     createOutBoundConnection called');
      logger.info('     Calling SecureSocketUtil.createSecureSocket with connect timeout $socketConnectTimeout');
      SecureSocket secureSocket;
      try {
        secureSocket =
            await SecureSocketUtil.createSecureSocket(host, port, secureSocketConfig, socketConnectTimeout: socketConnectTimeout);
      } catch (e) {
        logger.warning("Failed to create secure socket with exception $e");
        rethrow;
      }

      logger.info('     Creating OutboundConnectionImpl with the new secureSocket');
      _connection = OutboundConnectionImpl(secureSocket);
      if (outboundConnectionTimeout != null) {
        _connection!.setIdleTime(outboundConnectionTimeout);
      }
    } on SocketException {
      throw SecondaryConnectException('unable to connect to secondary $toAtSign on $host:$port');
    }
    return true;
  }

  bool isConnectionAvailable() {
    return _connection != null && !_connection!.isInValid();
  }

  bool isInValid() {
    return _connection!.isInValid();
  }

  ///performs network availability check before creating a connection
  ///throws AtConnectException when network is unavailable
  Future<void> networkAvailabilityCheck() async {
    if (!(await AtNetworkUtil.isNetworkAvailable())) {
      throw AtConnectException(
          'Failed to create connection due to network unavailability',
          exceptionScenario: ExceptionScenario.noNetworkConnectivity);
    }
  }

  Future<void> close() async {
    await _connection?.close();
  }

  Future<void> _sendCommand(String command) async {
    await createConnection();
    logger.finer('[$_serverNetworkSessionId] SENDING: $command');
    await _connection!.write(command);
  }

  @override
  set atChops(AtChops? atChops) {
    _atChops = atChops;
  }

  @override
  AtChops? get atChops => _atChops;
}
