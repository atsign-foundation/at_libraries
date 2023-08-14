// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/onboard/at_security_keys.dart';
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:at_utils/at_utils.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
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
  bool _isPkamAuthenticated = false;
  bool _isAtsignOnboarded = false;
  AtSignLogger logger = AtSignLogger('OnboardingCli');
  AtOnboardingPreference atOnboardingPreference;
  AtClient? _atClient;
  AtLookUp? _atLookUp;

  /// The object which controls what types of AtClients, NotificationServices
  /// and SyncServices get created when we call [AtClientManager.setCurrentAtSign].
  /// If [atServiceFactory] is not set, AtClientManager.setCurrentAtSign will use
  /// a [DefaultAtServiceFactory]
  AtServiceFactory? atServiceFactory;

  AtOnboardingServiceImpl(atsign, this.atOnboardingPreference,
      {this.atServiceFactory}) {
    // performs atSign format checks on the atSign
    _atSign = AtUtils.fixAtSign(atsign);

    // set default LocalStorage paths for this instance
    atOnboardingPreference.commitLogPath ??=
        HomeDirectoryUtil.getCommitLogPath(_atSign);
    atOnboardingPreference.hiveStoragePath ??=
        HomeDirectoryUtil.getHiveStoragePath(_atSign);
    atOnboardingPreference.isLocalStoreRequired = true;
    atOnboardingPreference.atKeysFilePath ??=
        HomeDirectoryUtil.getAtKeysPath(_atSign);
  }

  Future<void> _initAtClient(AtChops atChops) async {
    AtClientManager atClientManager = AtClientManager.getInstance();
    if (atOnboardingPreference.skipSync == true) {
      atServiceFactory = ServiceFactoryWithNoOpSyncService();
    }
    await atClientManager.setCurrentAtSign(
        _atSign, atOnboardingPreference.namespace, atOnboardingPreference,
        atChops: atChops, serviceFactory: atServiceFactory);
    // ??= to support mocking
    _atLookUp ??= atClientManager.atClient.getRemoteSecondary()?.atLookUp;
    _atLookUp?.signingAlgoType = atOnboardingPreference.signingAlgoType;
    _atLookUp?.hashingAlgoType = atOnboardingPreference.hashingAlgoType;
    _atClient ??= atClientManager.atClient;
  }

  Future<void> _init(AtSecurityKeys atKeysFile) async {
    atChops ??= _createAtChops(atKeysFile);
    await _initAtClient(atChops!);
    _atLookUp!.atChops = atChops;
    _atClient!.atChops = atChops;
    _atClient!.getPreferences()!.useAtChops = true;
  }

  @override
  @Deprecated('Use getter')
  Future<AtClient?> getAtClient() async {
    return _atClient;
  }

  @override
  Future<bool> onboard() async {
    if (atOnboardingPreference.appName == null ||
        atOnboardingPreference.deviceName == null) {
      throw AtOnboardingException(
          'appName and deviceName are mandatory for onboarding');
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

    try {
      // authenticate into secondary using cram secret
      _isAtsignOnboarded = (await atLookUpImpl
          .authenticate_cram(atOnboardingPreference.cramSecret));

      if (_isAtsignOnboarded) {
        logger.info('Cram authentication successful');
        await _activateAtsign(atLookUpImpl);
      } else {
        throw AtActivateException(
            'Cram authentication failed. Please check the cram key'
            ' and try again \n(or) contact support@atsign.com');
      }
    } on Exception catch (e) {
      if (e.toString().contains('Auth failed')) {
        throw AtActivateException(
            'Cram authentication failed. Please check the cram key'
            ' and try again \n(or) contact support@atsign.com');
      }
      logger.severe('Caught exception: $e');
    } on Error catch (e, trace) {
      logger.severe('Caught error: $e $trace');
    } finally {
      await atLookUpImpl.close();
    }
    return _isAtsignOnboarded;
  }

  ///method to generate/update encryption key-pairs to activate an atsign
  Future<void> _activateAtsign(AtLookupImpl atLookUpImpl) async {
    //1. Generate pkam key pair(if authMode is keyFile), encryption key pair, self encryption key and apkam symmetric key pair
    AtSecurityKeys atSecurityKeys = await _generateKeyPairs();

    var enrollBuilder = EnrollVerbBuilder()
      ..appName = atOnboardingPreference.appName
      ..deviceName = atOnboardingPreference.deviceName;

    // #TODO replace encryption util methods with at_chops methods when refactoring
    enrollBuilder.encryptedDefaultEncryptedPrivateKey =
        EncryptionUtil.encryptValue(atSecurityKeys.defaultEncryptionPrivateKey!,
            atSecurityKeys.apkamSymmetricKey!);
    enrollBuilder.encryptedDefaultSelfEncryptionKey =
        EncryptionUtil.encryptValue(atSecurityKeys.defaultSelfEncryptionKey!,
            atSecurityKeys.apkamSymmetricKey!);
    enrollBuilder.apkamPublicKey = atSecurityKeys.apkamPublicKey;
    print(enrollBuilder.buildCommand());

    //2. Send enroll request to server
    var enrollResult = await atLookUpImpl
        .executeCommand(enrollBuilder.buildCommand(), auth: false);
    if (enrollResult == null || enrollResult.isEmpty) {
      throw AtOnboardingException('Enrollment response is null or empty');
    } else if (enrollResult.startsWith('error:')) {
      throw AtOnboardingException('Enrollment error:$enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    print('***enrollResult: $enrollResult');
    var enrollResultJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollResultJson[enrollmentId];
    var enrollmentStatus = enrollResultJson['status'];
    if (enrollmentStatus != 'approved') {
      throw AtOnboardingException(
          'initial enrollment is not approved. Status from server: $enrollmentStatus');
    }
    atSecurityKeys.enrollmentId = enrollmentIdFromServer;

    //3. Close connection to server
    try {
      atLookUpImpl.close();
    } on Exception catch (e) {
      logger.severe('error while closing connection to server: $e');
    }

    //4. initialise atClient and atChops and attempt a pkam auth to server.
    await _init(atSecurityKeys);

    //4. create new connection to server and do pkam with enrollmentId
    try {
      _isPkamAuthenticated = await _atLookUp!
          .pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
    } on UnAuthenticatedException {
      throw AtOnboardingException(
          'Pkam auth with enrollmentId-$enrollmentIdFromServer failed');
    }
    if (!_isPkamAuthenticated) {
      throw AtOnboardingException(
          'Pkam auth with enrollmentId-$enrollmentIdFromServer failed');
    }
    print('*** _isPkamAuthenticated:$_isPkamAuthenticated');
    //2. generate .atKeys file using a copy of atKeysMap

    // _isPkamAuthenticated = (await _atLookUp?.pkamAuthenticate())!;

    //5. If Pkam auth is success, update encryption public key to secondary and delete cram key from server
    if (_isPkamAuthenticated) {
      final encryptionPublicKey = atSecurityKeys.defaultEncryptionPublicKey;
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = encryptionPublicKey
        ..sharedBy = _atSign;
      String? encryptKeyUpdateResult =
          await _atLookUp!.executeVerb(updateBuilder);
      logger
          .info('Encryption public key update result $encryptKeyUpdateResult');
      // deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await _atLookUp!.executeVerb(deleteBuilder);
      logger.info('Cram secret delete response : $deleteResponse');
      //displays status of the atsign
      logger.finer(await getServerStatus());
      stdout.writeln('[Success]----------atSign activated---------');
      stdout.writeln('-----------------saving atkeys file---------');
      await _generateAtKeysFile(enrollmentIdFromServer, atSecurityKeys);
    }
  }

  AtSecurityKeys _generateKeyPairs() {
    // generate user encryption keypair
    logger.info('Generating encryption keypair');
    var encryptionKeyPair = generateRsaKeypair();

    //generate selfEncryptionKey
    var selfEncryptionKey = generateAESKey();
    var apkamSymmetricKey = generateAESKey();
    var atKeysFile = AtSecurityKeys();
    stdout.writeln(
        '[Information] Generating your encryption keys and .atKeys file\n');
    late String apkamPublicKey;
    //generating pkamKeyPair only if authMode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      logger.info('Generating pkam keypair');
      var apkamRsaKeypair = generateRsaKeypair();
      atKeysFile.apkamPublicKey = apkamRsaKeypair.publicKey.toString();
      atKeysFile.apkamPrivateKey = apkamRsaKeypair.privateKey.toString();
      print('apkamPrivateKey:${atKeysFile.apkamPrivateKey}');
      apkamPublicKey = apkamRsaKeypair.publicKey.toString();
    } else if (atOnboardingPreference.authMode == PkamAuthMode.sim) {
      // get the public key from secure element
      apkamPublicKey =
          atChops!.readPublicKey(atOnboardingPreference.publicKeyId!);
      logger.info('pkam  public key from sim: $apkamPublicKey');

      // encryption key pair and self encryption symmetric key
      // are not available to injected at_chops. Set it here
      atChops!.atChopsKeys.atEncryptionKeyPair = AtEncryptionKeyPair.create(
          encryptionKeyPair.publicKey.toString(),
          encryptionKeyPair.privateKey.toString());
      atChops!.atChopsKeys.selfEncryptionKey = AESKey(selfEncryptionKey);
      atChops!.atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);
    }
    atKeysFile.apkamPublicKey = apkamPublicKey;
    //Standard order of an atKeys file is ->
    // pkam keypair -> encryption keypair -> selfEncryption key -> enrollmentId --> apkam symmetric key -->
    // @sign: selfEncryptionKey[self encryption key again]
    // note: "->" stands for "followed by"
    atKeysFile.defaultEncryptionPublicKey =
        encryptionKeyPair.publicKey.toString();
    atKeysFile.defaultEncryptionPrivateKey =
        encryptionKeyPair.privateKey.toString();
    atKeysFile.defaultSelfEncryptionKey = selfEncryptionKey;
    atKeysFile.apkamSymmetricKey = apkamSymmetricKey;

    return atKeysFile;
  }

  ///write newly created encryption keypairs into atKeys file
  Future<void> _generateAtKeysFile(
      String currentEnrollmentId, AtSecurityKeys atSecurityKeys) async {
    Map<String, String> atKeysMap = {};
    //encrypting all keys with self encryption key
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
          atSecurityKeys.apkamPrivateKey!,
          atSecurityKeys.defaultSelfEncryptionKey!);
    }
    atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.encryptValue(
        atSecurityKeys.apkamPublicKey!,
        atSecurityKeys.defaultSelfEncryptionKey!);
    atKeysMap[AuthKeyType.encryptionPublicKey] = EncryptionUtil.encryptValue(
        atSecurityKeys.defaultEncryptionPublicKey!,
        atSecurityKeys.defaultSelfEncryptionKey!);
    atKeysMap[AuthKeyType.encryptionPrivateKey] = EncryptionUtil.encryptValue(
        atSecurityKeys.defaultEncryptionPrivateKey!,
        atSecurityKeys.defaultSelfEncryptionKey!);
    atKeysMap[AuthKeyType.selfEncryptionKey] =
        atSecurityKeys.defaultSelfEncryptionKey!;
    atKeysMap[_atSign] = atSecurityKeys.defaultSelfEncryptionKey!;
    atKeysMap[AuthKeyType.apkamSymmetricKey] =
        atSecurityKeys.apkamSymmetricKey!;
    atKeysMap['enrollmentId'] = currentEnrollmentId;

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
  Future<void> _persistKeysLocalSecondary() async {
    //when authenticating keys need to be fetched from atKeys file
    Map<String, String> atKeysMap = await _decryptAtKeysFile(
        (await _readAtKeysFile(atOnboardingPreference.atKeysFilePath)));
    //backup keys into local secondary
    bool? response = await _atClient
        ?.getLocalSecondary()
        ?.putValue(AT_PKAM_PUBLIC_KEY, atKeysMap[AuthKeyType.pkamPublicKey]!);
    logger.finer('PkamPublicKey persist to localSecondary: status $response');
    // save pkam private key only when auth mode is keyFile. if auth mode is sim/any other secure element private key cannot be read and hence will not be part of keys file
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_PKAM_PRIVATE_KEY, atKeysMap[AuthKeyType.pkamPrivateKey]!);
      logger
          .finer('PkamPrivateKey persist to localSecondary: status $response');
    }
    response = await _atClient?.getLocalSecondary()?.putValue(
        '$AT_ENCRYPTION_PUBLIC_KEY$_atSign',
        atKeysMap[AuthKeyType.encryptionPublicKey]!);
    logger.finer(
        'EncryptionPublicKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_PRIVATE_KEY,
        atKeysMap[AuthKeyType.encryptionPrivateKey]!);
    logger.finer(
        'EncryptionPrivateKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_SELF_KEY, atKeysMap[AuthKeyType.selfEncryptionKey]!);
    logger
        .finer('SelfEncryptionKey persist to localSecondary: status $response');
  }

  @override
  Future<bool> authenticate() async {
    // decrypts all the keys in .atKeysFile using the SelfEncryptionKey
    // and stores the keys in a map
    var atKeysFileDataMap = await _decryptAtKeysFile(
        await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    var pkamPrivateKey = atKeysFileDataMap[AuthKeyType.pkamPrivateKey];

    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile &&
        pkamPrivateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Unable to read PkamPrivateKey from provided atKeys file at path: '
          '${atOnboardingPreference.atKeysFilePath}. Please provide a valid atKeys file',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    // #TODO replace with AtKeysFile
    // await _init(atKeysFileDataMap);
    logger.finer('Authenticating using PKAM');
    try {
      _isPkamAuthenticated = (await _atLookUp?.pkamAuthenticate())!;
    } on Exception catch (e) {
      logger.severe('Caught exception: $e');
      throw UnAuthenticatedException('Unable to authenticate.'
          ' Please provide a valid keys file');
    }
    logger.finer(
        'PKAM auth result: ${_isPkamAuthenticated ? 'success' : 'failed'}');

    if (!_isAtsignOnboarded && atOnboardingPreference.atKeysFilePath != null) {
      await _persistKeysLocalSecondary();
    }

    return _isPkamAuthenticated;
  }

  AtChops _createAtChops(AtSecurityKeys atKeysFile) {
    final atEncryptionKeyPair = AtEncryptionKeyPair.create(
        atKeysFile.defaultEncryptionPublicKey!,
        atKeysFile.defaultEncryptionPrivateKey!);
    final atPkamKeyPair = AtPkamKeyPair.create(
        atKeysFile.apkamPublicKey!, atKeysFile.apkamPrivateKey!);
    final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
    atChopsKeys.apkamSymmetricKey = AESKey(atKeysFile.apkamSymmetricKey!);
    atChopsKeys.selfEncryptionKey =
        AESKey(atKeysFile.defaultSelfEncryptionKey!);
    return AtChopsImpl(atChopsKeys);
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

  ///decrypt keys using self_encryption_key
  ///returns map containing decrypted atKeys
  Future<Map<String, String>> _decryptAtKeysFile(
      Map<String, String> jsonData) async {
    String decryptionKey = _getDecryptionKey(jsonData);
    Map<String, String> atKeysMap = <String, String>{
      AuthKeyType.encryptionPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPublicKey]!, decryptionKey),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPrivateKey]!, decryptionKey),
      AuthKeyType.selfEncryptionKey: decryptionKey,
    };
    atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.pkamPublicKey]!, decryptionKey);
    // pkam private key will not be saved in keyfile if auth mode is sim/any other secure element.
    // decrypt the private key only when auth mode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey]!, decryptionKey);
    }
    return atKeysMap;
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
    _atClient = null;
    logger.info(
        'Closing current instance of at_onboarding_cli (exit code: $exitCode)');
  }

  @override
  @Deprecated('Use getter')
  AtLookUp? getAtLookup() {
    return _atLookUp;
  }

  @override
  set atClient(AtClient? atClient) {
    _atClient = atClient;
  }

  @override
  set atLookUp(AtLookUp? atLookUp) {
    _atLookUp = atLookUp;
  }

  @override
  AtClient? get atClient => _atClient;

  @override
  AtLookUp? get atLookUp => _atLookUp;

  @override
  AtChops? atChops;
}
