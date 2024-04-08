// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_auth/at_auth.dart' as at_auth;
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:at_utils/at_utils.dart';
import 'package:at_onboarding_cli/src/factory/service_factories.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

import '../util/home_directory_util.dart';
import '../util/onboarding_util.dart';

///class containing service that can onboard/activate/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  late final String _atSign;
  bool _isAtsignOnboarded = false;
  AtSignLogger logger = AtSignLogger('OnboardingCli');
  AtOnboardingPreference atOnboardingPreference;
  AtLookUp? _atLookUp;

  final StreamController<String> _pkamSuccessController =
      StreamController<String>();

  Stream<dynamic> get _onPkamSuccess => _pkamSuccessController.stream;

  /// The object which controls what types of AtClients, NotificationServices
  /// and SyncServices get created when we call [AtClientManager.setCurrentAtSign].
  /// If [atServiceFactory] is not set, AtClientManager.setCurrentAtSign will use
  /// a [DefaultAtServiceFactory]
  AtServiceFactory? atServiceFactory;

  at_auth.AtEnrollmentBase? _atEnrollmentBase;

  AtOnboardingServiceImpl(atsign, this.atOnboardingPreference,
      {this.atServiceFactory, String? enrollmentId}) {
    // performs atSign format checks on the atSign
    _atSign = AtUtils.fixAtSign(atsign);
    _atEnrollmentBase ??= at_auth.atAuthBase.atEnrollment(_atSign);
    // set default LocalStorage paths for this instance
    atOnboardingPreference.commitLogPath ??=
        HomeDirectoryUtil.getCommitLogPath(_atSign, enrollmentId: enrollmentId);
    atOnboardingPreference.hiveStoragePath ??=
        HomeDirectoryUtil.getHiveStoragePath(_atSign,
            enrollmentId: enrollmentId);
    atOnboardingPreference.isLocalStoreRequired = true;
    atOnboardingPreference.atKeysFilePath ??=
        HomeDirectoryUtil.getAtKeysPath(_atSign);
  }

  Future<void> _initAtClient(AtChops atChops, {String? enrollmentId}) async {
    AtClientManager atClientManager = AtClientManager.getInstance();
    if (atOnboardingPreference.skipSync == true) {
      atServiceFactory = ServiceFactoryWithNoOpSyncService();
    }
    await atClientManager.setCurrentAtSign(
        _atSign, atOnboardingPreference.namespace, atOnboardingPreference,
        atChops: atChops,
        serviceFactory: atServiceFactory,
        enrollmentId: enrollmentId);
    // ??= to support mocking
    _atLookUp ??= atClientManager.atClient.getRemoteSecondary()?.atLookUp;
    _atLookUp?.enrollmentId = enrollmentId;
    _atLookUp?.signingAlgoType = atOnboardingPreference.signingAlgoType;
    _atLookUp?.hashingAlgoType = atOnboardingPreference.hashingAlgoType;
    atClient ??= atClientManager.atClient;
    _atLookUp!.atChops = atChops;
  }

  @override
  @Deprecated('Use getter')
  Future<AtClient?> getAtClient() async {
    return atClient;
  }

  @override
  Future<bool> onboard() async {
    if (atOnboardingPreference.appName == null ||
        atOnboardingPreference.deviceName == null) {
      throw AtOnboardingException(
          'appName and deviceName are mandatory for onboarding. Please set the params in AtOnboardingPreference');
    }
    // cram auth doesn't use at_chops. So create at_lookup here.
    AtLookupImpl atLookUpImpl = AtLookupImpl(_atSign,
        atOnboardingPreference.rootDomain, atOnboardingPreference.rootPort);

    // get cram_secret from either from AtOnboardingPreference
    // or fetch from the registrar using verification code sent to email
    atOnboardingPreference.cramSecret ??= await OnboardingUtil()
        .getCramUsingOtp(_atSign, atOnboardingPreference.registrarUrl);
    if (atOnboardingPreference.cramSecret == null) {
      logger.info('Root Server address is ${atOnboardingPreference.rootDomain}:'
          '${atOnboardingPreference.rootPort}');
      logger
          .info('Registrar url is \'${atOnboardingPreference.registrarUrl}\'');
      throw AtKeyNotFoundException(
          'Could not fetch cram secret for \'$_atSign\' from registrar');
    }

    // check and wait till secondary exists
    await _waitUntilSecondaryCreated(atLookUpImpl);

    if (await isOnboarded()) {
      throw AtActivateException('atsign is already activated');
    }

    atAuth ??= at_auth.atAuthBase.atAuth();
    var atOnboardingRequest = at_auth.AtOnboardingRequest(_atSign);
    atOnboardingRequest.rootDomain = atOnboardingPreference.rootDomain;
    atOnboardingRequest.rootPort = atOnboardingPreference.rootPort;
    atOnboardingRequest.appName = atOnboardingPreference.appName;
    atOnboardingRequest.deviceName = atOnboardingPreference.deviceName;
    atOnboardingRequest.publicKeyId = atOnboardingPreference.publicKeyId;
    var atOnboardingResponse = await atAuth!
        .onboard(atOnboardingRequest, atOnboardingPreference.cramSecret!);
    logger.finer('Onboarding Response: $atOnboardingResponse');
    if (atOnboardingResponse.isSuccessful) {
      logger.finer(
          'Onboarding successful.Generating keyfile in path: ${atOnboardingPreference.atKeysFilePath}');
      await _generateAtKeysFile(
          atOnboardingResponse.enrollmentId, atOnboardingResponse.atAuthKeys!);
    }
    _isAtsignOnboarded = atOnboardingResponse.isSuccessful;
    return _isAtsignOnboarded;
  }

  @override
  Future<at_auth.AtEnrollmentResponse> enroll(String appName, String deviceName,
      String otp, Map<String, String> namespaces,
      {int? pkamRetryIntervalMins}) async {
    if (appName == null || deviceName == null) {
      throw AtEnrollmentException(
          'appName and deviceName are mandatory for enrollment');
    }
    pkamRetryIntervalMins ??= atOnboardingPreference.apkamAuthRetryDurationMins;
    final Duration retryInterval = Duration(minutes: pkamRetryIntervalMins);

    AtLookupImpl atLookUpImpl = AtLookupImpl(_atSign,
        atOnboardingPreference.rootDomain, atOnboardingPreference.rootPort);

    //2. Send enroll request to server
    at_auth.AtEnrollmentResponse enrollmentResponse = await _sendEnrollRequest(
        appName, deviceName, otp, namespaces, atLookUpImpl);
    logger.finer('EnrollmentResponse from server: $enrollmentResponse');

    AtChopsKeys atChopsKeys = AtChopsKeys.create(
        AtEncryptionKeyPair.create(
            enrollmentResponse.atAuthKeys!.defaultEncryptionPublicKey!, ''),
        AtPkamKeyPair.create(enrollmentResponse.atAuthKeys!.apkamPublicKey!,
            enrollmentResponse.atAuthKeys!.apkamPrivateKey!));
    atChopsKeys.apkamSymmetricKey =
        AESKey(enrollmentResponse.atAuthKeys!.apkamSymmetricKey!);

    atLookUpImpl.atChops = AtChopsImpl(atChopsKeys);

    // Pkam auth will be attempted asynchronously until enrollment is approved/denied
    _attemptPkamAuthAsync(
        atLookUpImpl, enrollmentResponse.enrollmentId, retryInterval);

    // Upon successful pkam auth, callback _listenToPkamSuccessStream will  be invoked
    _listenToPkamSuccessStream(
        atLookUpImpl,
        enrollmentResponse.atAuthKeys!.apkamSymmetricKey!,
        enrollmentResponse.atAuthKeys!.defaultEncryptionPublicKey!,
        enrollmentResponse.atAuthKeys!.apkamPublicKey!,
        enrollmentResponse.atAuthKeys!.apkamPrivateKey!);

    return enrollmentResponse;
  }

  void _listenToPkamSuccessStream(
      AtLookupImpl atLookUpImpl,
      String apkamSymmetricKey,
      String defaultEncryptionPublicKey,
      String apkamPublicKey,
      String apkamPrivateKey) {
    _onPkamSuccess.listen((enrollmentIdFromServer) async {
      logger.finer('_listenToPkamSuccessStream invoked');
      var decryptedEncryptionPrivateKey = EncryptionUtil.decryptValue(
          await _getEncryptionPrivateKeyFromServer(
              enrollmentIdFromServer, atLookUpImpl),
          apkamSymmetricKey);
      var decryptedSelfEncryptionKey = EncryptionUtil.decryptValue(
          await _getSelfEncryptionKeyFromServer(
              enrollmentIdFromServer, atLookUpImpl),
          apkamSymmetricKey);

      var atAuthKeys = at_auth.AtAuthKeys()
        ..defaultEncryptionPrivateKey = decryptedEncryptionPrivateKey
        ..defaultEncryptionPublicKey = defaultEncryptionPublicKey
        ..apkamSymmetricKey = apkamSymmetricKey
        ..defaultSelfEncryptionKey = decryptedSelfEncryptionKey
        ..apkamPublicKey = apkamPublicKey
        ..apkamPrivateKey = apkamPrivateKey;
      logger.finer('Generating keys file for $enrollmentIdFromServer');
      await _generateAtKeysFile(enrollmentIdFromServer, atAuthKeys);
    });
  }

  Future<String> _getEncryptionPrivateKeyFromServer(
      String enrollmentIdFromServer, AtLookUp atLookUp) async {
    var privateKeyCommand =
        'keys:get:keyName:$enrollmentIdFromServer.${AtConstants.defaultEncryptionPrivateKey}.__manage$_atSign\n';
    String encryptionPrivateKeyFromServer;
    try {
      var getPrivateKeyResult =
          await atLookUp.executeCommand(privateKeyCommand, auth: true);
      if (getPrivateKeyResult == null || getPrivateKeyResult.isEmpty) {
        throw AtEnrollmentException('$privateKeyCommand returned null/empty');
      }
      getPrivateKeyResult = getPrivateKeyResult.replaceFirst('data:', '');
      var privateKeyResultJson = jsonDecode(getPrivateKeyResult);
      encryptionPrivateKeyFromServer = privateKeyResultJson['value'];
    } on Exception catch (e) {
      throw AtEnrollmentException(
          'Exception while getting encrypted private key/self key from server: $e');
    }
    return encryptionPrivateKeyFromServer;
  }

  Future<String> _getSelfEncryptionKeyFromServer(
      String enrollmentIdFromServer, AtLookUp atLookUp) async {
    var selfEncryptionKeyCommand =
        'keys:get:keyName:$enrollmentIdFromServer.${AtConstants.defaultSelfEncryptionKey}.__manage$_atSign\n';
    String selfEncryptionKeyFromServer;
    try {
      var getSelfEncryptionKeyResult =
          await atLookUp.executeCommand(selfEncryptionKeyCommand, auth: true);
      if (getSelfEncryptionKeyResult == null ||
          getSelfEncryptionKeyResult.isEmpty) {
        throw AtEnrollmentException(
            '$selfEncryptionKeyCommand returned null/empty');
      }
      getSelfEncryptionKeyResult =
          getSelfEncryptionKeyResult.replaceFirst('data:', '');
      var selfEncryptionKeyResultJson = jsonDecode(getSelfEncryptionKeyResult);
      selfEncryptionKeyFromServer = selfEncryptionKeyResultJson['value'];
    } on Exception catch (e) {
      throw AtEnrollmentException(
          'Exception while getting encrypted private key/self key from server: $e');
    }
    return selfEncryptionKeyFromServer;
  }

  Future<void> _attemptPkamAuthAsync(AtLookupImpl atLookUpImpl,
      String enrollmentIdFromServer, Duration retryInterval) async {
    // Pkam auth will be retried until server approves/denies/expires the enrollment
    while (true) {
      logger.finer('Attempting pkam for $enrollmentIdFromServer');
      bool pkamAuthResult = await _attemptPkamAuth(
          atLookUpImpl, enrollmentIdFromServer, retryInterval);
      if (pkamAuthResult) {
        logger.finer('Pkam auth successful for $enrollmentIdFromServer');
        _pkamSuccessController.add(enrollmentIdFromServer);
        break;
      }
      logger.finer('Retrying pkam after mins: $retryInterval');
      await Future.delayed(retryInterval); // Delay and retry
    }
  }

  Future<bool> _attemptPkamAuth(AtLookUp atLookUp,
      String enrollmentIdFromServer, Duration retryInterval) async {
    try {
      var pkamResult =
          await atLookUp.pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
      if (pkamResult) {
        return true;
      }
    } on UnAuthenticatedException catch (e) {
      if (e.message.contains('error:AT0401') ||
          e.message.contains('error:AT0026')) {
        logger.finer('Pkam auth failed: ${e.message}');
        return false;
      } else if (e.message.contains('error:AT0025')) {
        logger.finer(
            'enrollmentId $enrollmentIdFromServer denied.Exiting pkam retry logic');
        throw AtEnrollmentException('enrollment denied');
      }
    }
    return false;
  }

  Future<at_auth.AtEnrollmentResponse> _sendEnrollRequest(
      String appName,
      String deviceName,
      String otp,
      Map<String, String> namespaces,
      AtLookupImpl atLookUpImpl) async {
    at_auth.EnrollmentRequest newClientEnrollmentRequest =
        at_auth.EnrollmentRequest(
            appName: appName,
            deviceName: deviceName,
            namespaces: namespaces,
            otp: otp);
    logger.finer('calling at_enrollment_impl submit enrollment');
    return await _atEnrollmentBase!
        .submit(newClientEnrollmentRequest, atLookUpImpl);
  }

  ///write newly created encryption keypairs into atKeys file
  Future<void> _generateAtKeysFile(
      String? currentEnrollmentId, at_auth.AtAuthKeys atAuthKeys) async {
    final atKeysMap = <String, String>{
      AuthKeyType.pkamPublicKey: EncryptionUtil.encryptValue(
        atAuthKeys.apkamPublicKey!,
        atAuthKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.encryptionPublicKey: EncryptionUtil.encryptValue(
        atAuthKeys.defaultEncryptionPublicKey!,
        atAuthKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.encryptValue(
        atAuthKeys.defaultEncryptionPrivateKey!,
        atAuthKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.selfEncryptionKey: atAuthKeys.defaultSelfEncryptionKey!,
      _atSign: atAuthKeys.defaultSelfEncryptionKey!,
      AuthKeyType.apkamSymmetricKey: atAuthKeys.apkamSymmetricKey!
    };

    if (currentEnrollmentId != null) {
      atKeysMap['enrollmentId'] = currentEnrollmentId;
    }

    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
          atAuthKeys.apkamPrivateKey!, atAuthKeys.defaultSelfEncryptionKey!);
    }

    if (!atOnboardingPreference.atKeysFilePath!.endsWith('.atKeys')) {
      atOnboardingPreference.atKeysFilePath =
          path.join(atOnboardingPreference.atKeysFilePath!, '.atKeys');
    }

    File atKeysFile = File(atOnboardingPreference.atKeysFilePath!);

    if (!atKeysFile.existsSync()) {
      atKeysFile.createSync(recursive: true);
    }
    IOSink fileWriter = atKeysFile.openWrite();

    //generating .atKeys file at path provided in onboardingConfig
    fileWriter.write(jsonEncode(atKeysMap));
    await fileWriter.flush();
    await fileWriter.close();
    stdout.writeln(
        '[Success] Your .atKeys file saved at ${atOnboardingPreference.atKeysFilePath}\n');
  }

  ///back-up encryption keys to local secondary
  /// #TODO remove this method in future when all keys are read from AtChops
  Future<void> _persistKeysLocalSecondary() async {
    //when authenticating keys need to be fetched from atKeys file
    at_auth.AtAuthKeys atAuthKeys = _decryptAtKeysFile(
        (await _readAtKeysFile(atOnboardingPreference.atKeysFilePath)));
    //backup keys into local secondary
    bool? response = await atClient
        ?.getLocalSecondary()
        ?.putValue(AtConstants.atPkamPublicKey, atAuthKeys.apkamPublicKey!);
    logger.finer('PkamPublicKey persist to localSecondary: status $response');
    // save pkam private key only when auth mode is keyFile. if auth mode is sim/any other secure element private key cannot be read and hence will not be part of keys file
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      response = await atClient
          ?.getLocalSecondary()
          ?.putValue(AtConstants.atPkamPrivateKey, atAuthKeys.apkamPrivateKey!);
      logger
          .finer('PkamPrivateKey persist to localSecondary: status $response');
    }
    response = await atClient?.getLocalSecondary()?.putValue(
        '${AtConstants.atEncryptionPublicKey}$_atSign',
        atAuthKeys.defaultEncryptionPublicKey!);
    logger.finer(
        'EncryptionPublicKey persist to localSecondary: status $response');
    response = await atClient?.getLocalSecondary()?.putValue(
        AtConstants.atEncryptionPrivateKey,
        atAuthKeys.defaultEncryptionPrivateKey!);
    logger.finer(
        'EncryptionPrivateKey persist to localSecondary: status $response');
    response = await atClient?.getLocalSecondary()?.putValue(
        AtConstants.atEncryptionSelfKey, atAuthKeys.defaultSelfEncryptionKey!);
  }

  @override
  Future<bool> authenticate({String? enrollmentId}) async {
    atAuth ??= at_auth.atAuthBase.atAuth();
    var atAuthRequest = at_auth.AtAuthRequest(_atSign)
      ..enrollmentId = enrollmentId
      ..atKeysFilePath = atOnboardingPreference.atKeysFilePath
      ..authMode = atOnboardingPreference.authMode
      ..rootDomain = atOnboardingPreference.rootDomain
      ..rootPort = atOnboardingPreference.rootPort;
    var atAuthResponse = await atAuth!.authenticate(atAuthRequest);
    logger.finer('Auth response: $atAuthResponse');
    if (atAuthResponse.isSuccessful &&
        atOnboardingPreference.atKeysFilePath != null) {
      logger.finer('Calling persist keys to local secondary');
      await _initAtClient(atAuth!.atChops!,
          enrollmentId: atAuthResponse.enrollmentId);
      await _persistKeysLocalSecondary();
    }

    return atAuthResponse.isSuccessful;
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map<String, String>> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath == null || atKeysFilePath.isEmpty) {
      throw AtClientException.message(
          'atKeys filePath is empty. atKeysFile is required to authenticate');
    }
    String atAuthData = await File(atKeysFilePath).readAsString();
    Map<String, String> jsonData = <String, String>{};
    json.decode(atAuthData).forEach((String key, dynamic value) {
      jsonData[key] = value.toString();
    });
    return jsonData;
  }

  ///method to extract decryption key from atKeysData
  ///returns self_encryption_key
  String _getDecryptionKey(Map<String, String>? jsonData) {
    return jsonData![AuthKeyType.selfEncryptionKey]!;
  }

  at_auth.AtAuthKeys _decryptAtKeysFile(Map<String, String> jsonData) {
    var atAuthKeys = at_auth.AtAuthKeys();
    String decryptionKey = _getDecryptionKey(jsonData);
    atAuthKeys.defaultEncryptionPublicKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.encryptionPublicKey]!, decryptionKey);
    atAuthKeys.defaultEncryptionPrivateKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.encryptionPrivateKey]!, decryptionKey);
    atAuthKeys.defaultSelfEncryptionKey = decryptionKey;
    atAuthKeys.apkamPublicKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.pkamPublicKey]!, decryptionKey);
    // pkam private key will not be saved in keyfile if auth mode is sim/any other secure element.
    // decrypt the private key only when auth mode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atAuthKeys.apkamPrivateKey = EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey]!, decryptionKey);
    }
    atAuthKeys.apkamSymmetricKey = jsonData[AuthKeyType.apkamSymmetricKey];
    atAuthKeys.enrollmentId = jsonData[AtConstants.enrollmentId];
    return atAuthKeys;
  }

  ///generates random RSA keypair
  RSAKeypair generateRsaKeypair() {
    return RSAKeypair.fromRandom();
  }

  ///generate random AES key
  String generateAESKey() {
    return AES(Key.fromSecureRandom(32)).key.base64;
  }

  ///returns secondary server status
  Future<AtStatus> getServerStatus() {
    AtServerStatus atServerStatus = AtStatusImpl(
        rootUrl: atOnboardingPreference.rootDomain,
        rootPort: atOnboardingPreference.rootPort);
    return atServerStatus.get(_atSign);
  }

  @override
  Future<bool> isOnboarded() async {
    late AtStatus secondaryStatus;
    try {
      secondaryStatus = await getServerStatus();
    } catch (e) {
      stderr.writeln('[Error] $e');
    }
    if (secondaryStatus.status() == AtSignStatus.activated) {
      _isAtsignOnboarded = true;
      return _isAtsignOnboarded;
    } else if (secondaryStatus.status() == AtSignStatus.teapot) {
      return false;
    }
    stderr.writeln(
        '[Error] atsign($_atSign) status is \'${secondaryStatus.status()!.name}\'');
    throw AtActivateException('Could not determine atsign activation status',
        intent: Intent.fetchData);
  }

  ///extracts cram secret from qrCode
  @Deprecated('qr_code based cram authentication not supported anymore')
  static String? getSecretFromQr(String? path) {
    if (path == null) {
      return null;
    }
    try {
      Image? image = decodePng(File(path).readAsBytesSync());
      LuminanceSource source = RGBLuminanceSource(
          image!.width, image.height, image.getBytes().buffer.asInt32List());
      BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      Result result = QRCodeReader().decode(bitmap);
      String secret = result.text.split(':')[1];
      return secret;
    } on Exception catch (e) {
      stdout.writeln('exception while getting secret from QR code: $e');
      return null;
    }
  }

  ///Method to check if secondary belonging to [_atSign] exists
  ///If not, wait until secondary is created
  Future<void> _waitUntilSecondaryCreated(AtLookupImpl atLookupImpl) async {
    final maxRetries = 50;
    int retryCount = 1;
    SecondaryAddress? secondaryAddress;
    SecureSocket? secureSocket;
    bool connectionFlag = false;

    while (retryCount <= maxRetries && secondaryAddress == null) {
      await Future.delayed(Duration(seconds: 2));
      logger.finer('retrying find secondary.......$retryCount/$maxRetries');
      try {
        secondaryAddress =
            await atLookupImpl.secondaryAddressFinder.findSecondary(_atSign);
      } on Exception catch (e, trace) {
        logger.finer(e);
        logger.finer(trace);
      } on Error catch (e, trace) {
        logger.finer(e);
        logger.finer(trace);
      }
      retryCount++;
    }
    if (secondaryAddress == null) {
      throw SecondaryNotFoundException('Could not find secondary address for '
          '$_atSign after $retryCount retries. Please retry the process');
    }
    //resetting retry counter to be used for different operation
    retryCount = 1;

    while (!connectionFlag && retryCount <= maxRetries) {
      await Future.delayed(Duration(seconds: 2));
      stdout.writeln('Connecting to secondary ...$retryCount/$maxRetries');
      try {
        secureSocket = await SecureSocket.connect(
            secondaryAddress.host, secondaryAddress.port,
            timeout: Duration(
                seconds:
                    30)); // 30-second timeout should be enough even for slow networks
        connectionFlag = secureSocket.remoteAddress != null &&
            secureSocket.remotePort != null;
      } on Exception catch (e, trace) {
        logger.finer(e);
        logger.finer(trace);
      } on Error catch (e, trace) {
        logger.finer(e);
        logger.finer(trace);
      }
      retryCount++;
    }
  }

  @override
  Future<void> close() async {
    if (_atLookUp != null) {
      await (_atLookUp as AtLookupImpl).close();
    }
    _atLookUp = null;
    atClient = null;
    logger.info('Closing current instance of at_onboarding_cli (exit code: 0)');
    exit(0);
  }

  @override
  @Deprecated('Use getter')
  AtLookUp? getAtLookup() {
    return _atLookUp;
  }

  @override
  AtClient? atClient;

  @override
  set atLookUp(AtLookUp? atLookUp) {
    _atLookUp = atLookUp;
  }

  @override
  AtLookUp? get atLookUp => _atLookUp;

  @override
  @Deprecated('AtChops will be created in AtAuth')
  AtChops? atChops;

  @override
  at_auth.AtAuth? atAuth;
}
