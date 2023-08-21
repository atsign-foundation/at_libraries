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
    _atLookUp?.enrollmentId = atOnboardingPreference.enrollmentId;
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

  @override
  Future<EnrollResponse> enroll(String appName, String deviceName, String totp,
      Map<String, String> namespaces) async {
    if (appName == null || deviceName == null) {
      throw AtEnrollmentException(
          'appName and deviceName are mandatory for enrollment');
    }
    final Duration retryInterval =
        Duration(minutes: atOnboardingPreference.apkamAuthRetryDurationMins);
    logger.info('Generating apkam encryption keypair');
    //1. Generate new apkam key pair and apkam symmetric key
    var apkamKeyPair = generateRsaKeypair();
    var apkamSymmetricKey = generateAESKey();

    AtLookupImpl atLookUpImpl = AtLookupImpl(_atSign,
        atOnboardingPreference.rootDomain, atOnboardingPreference.rootPort);

    //2. Retrieve default encryption public key and encrypt apkam symmetric key
    var defaultEncryptionPublicKey =
        await _retrieveEncryptionPublicKey(atLookUpImpl);
    var encryptedApkamSymmetricKey = EncryptionUtil.encryptKey(
        apkamSymmetricKey, defaultEncryptionPublicKey);

    //3. Send enroll request to server
    var enrollmentResponse = await _sendEnrollRequest(
        appName,
        deviceName,
        totp,
        namespaces,
        apkamKeyPair.publicKey.toString(),
        encryptedApkamSymmetricKey,
        atLookUpImpl);

    //4. Create at chops instance
    var atChopsKeys = AtChopsKeys.create(
        null,
        AtPkamKeyPair.create(apkamKeyPair.publicKey.toString(),
            apkamKeyPair.privateKey.toString()));
    atLookUpImpl.atChops = AtChopsImpl(atChopsKeys);

    //5. try pkam auth every 30 mins or configured time interval until enrollment timesout or approved/denied by another authorized app
    var pkamAuthResult = false;
    while (!pkamAuthResult) {
      pkamAuthResult = await _attemptPkamAuth(
          atLookUpImpl, enrollmentResponse.enrollmentId, retryInterval);
    }
    if (!pkamAuthResult) {
      throw AtEnrollmentException(
          'Pkam auth with enrollmentId: ${enrollmentResponse.enrollmentId} failed after multiple retries');
    }

    //6. Retrieve encrypted keys from server
    var decryptedEncryptionPrivateKey = EncryptionUtil.decryptValue(
        await _getEncryptionPrivateKeyFromServer(
            enrollmentResponse.enrollmentId, atLookUpImpl),
        apkamSymmetricKey);
    var decryptedSelfEncryptionKey = EncryptionUtil.decryptValue(
        await _getSelfEncryptionKeyFromServer(
            enrollmentResponse.enrollmentId, atLookUpImpl),
        apkamSymmetricKey);

    //7. Save security keys and enrollmentId in atKeys file
    var atSecurityKeys = AtSecurityKeys()
      ..defaultEncryptionPrivateKey = decryptedEncryptionPrivateKey
      ..defaultEncryptionPublicKey = defaultEncryptionPublicKey
      ..apkamSymmetricKey = apkamSymmetricKey
      ..defaultSelfEncryptionKey = decryptedSelfEncryptionKey
      ..apkamPublicKey = apkamKeyPair.publicKey.toString()
      ..apkamPrivateKey = apkamKeyPair.privateKey.toString();
    await _generateAtKeysFile(enrollmentResponse.enrollmentId, atSecurityKeys);
    if (pkamAuthResult) {
      enrollmentResponse.enrollStatus = EnrollStatus.approved;
    }
    return enrollmentResponse;
  }

  Future<String> _getEncryptionPrivateKeyFromServer(
      String enrollmentIdFromServer, AtLookUp atLookUp) async {
    var privateKeyCommand =
        'keys:get:keyName:$enrollmentIdFromServer.$defaultEncryptionPrivateKey.__manage$_atSign\n';
    var encryptionPrivateKeyFromServer;
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
        'keys:get:keyName:$enrollmentIdFromServer.$defaultSelfEncryptionKey.__manage$_atSign\n';
    var selfEncryptionKeyFromServer;
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

  Future<bool> _attemptPkamAuth(AtLookUp atLookUp,
      String enrollmentIdFromServer, Duration retryInterval) async {
    try {
      var pkamResult =
          await atLookUp.pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
      if (pkamResult) {
        return true;
      }
    } on UnAuthenticatedException catch (e) {
      if (e.message.contains('error:AT0401')) {
        logger.finer('Retrying pkam auth');
        await Future.delayed(retryInterval);
      } else if (e.message.contains('error:AT0402')) {
        //# TODO change the error code once server bug is fixed
        logger.finer(
            'enrollmentId $enrollmentIdFromServer denied.Exiting pkam retry logic');
        throw AtEnrollmentException('enrollment denied');
      }
    }
    return false;
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

    //2. Send enroll request to server
    var enrollResult = await atLookUpImpl
        .executeCommand(enrollBuilder.buildCommand(), auth: false);
    if (enrollResult == null || enrollResult.isEmpty) {
      throw AtOnboardingException('Enrollment response is null or empty');
    } else if (enrollResult.startsWith('error:')) {
      throw AtOnboardingException('Enrollment error:$enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    logger.finer('enrollResult: $enrollResult');
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

  Future<EnrollResponse> _sendEnrollRequest(
      String appName,
      String deviceName,
      String totp,
      Map<String, String> namespaces,
      String apkamPublicKey,
      String encryptedApkamSymmetricKey,
      AtLookupImpl atLookUpImpl) async {
    var enrollVerbBuilder = EnrollVerbBuilder()
      ..appName = appName
      ..deviceName = deviceName
      ..namespaces = namespaces
      ..totp = totp
      ..apkamPublicKey = apkamPublicKey
      ..encryptedAPKAMSymmetricKey = encryptedApkamSymmetricKey;
    var enrollResult =
        await atLookUpImpl.executeCommand(enrollVerbBuilder.buildCommand());
    if (enrollResult == null ||
        enrollResult.isEmpty ||
        enrollResult.startsWith('error:')) {
      throw AtEnrollmentException(
          'Enrollment response from server: $enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    var enrollJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollJson[enrollmentId];
    logger.finer('enrollmentIdFromServer: $enrollmentIdFromServer');
    return EnrollResponse(enrollmentIdFromServer,
        getEnrollStatusFromString(enrollJson['status']));
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
    final atKeysMap = <String, String>{
      AuthKeyType.pkamPublicKey: EncryptionUtil.encryptValue(
        atSecurityKeys.apkamPublicKey!,
        atSecurityKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.encryptionPublicKey: EncryptionUtil.encryptValue(
        atSecurityKeys.defaultEncryptionPublicKey!,
        atSecurityKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.encryptValue(
        atSecurityKeys.defaultEncryptionPrivateKey!,
        atSecurityKeys.defaultSelfEncryptionKey!,
      ),
      AuthKeyType.selfEncryptionKey: atSecurityKeys.defaultSelfEncryptionKey!,
      _atSign: atSecurityKeys.defaultSelfEncryptionKey!,
      AuthKeyType.apkamSymmetricKey: atSecurityKeys.apkamSymmetricKey!,
      'enrollmentId': currentEnrollmentId,
    };

    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
          atSecurityKeys.apkamPrivateKey!,
          atSecurityKeys.defaultSelfEncryptionKey!);
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
  Future<void> _persistKeysLocalSecondary() async {
    //when authenticating keys need to be fetched from atKeys file
    AtSecurityKeys atSecurityKeys = _decryptAtKeysFile(
        (await _readAtKeysFile(atOnboardingPreference.atKeysFilePath)));
    //backup keys into local secondary
    bool? response = await _atClient
        ?.getLocalSecondary()
        ?.putValue(AT_PKAM_PUBLIC_KEY, atSecurityKeys.apkamPublicKey!);
    logger.finer('PkamPublicKey persist to localSecondary: status $response');
    // save pkam private key only when auth mode is keyFile. if auth mode is sim/any other secure element private key cannot be read and hence will not be part of keys file
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      response = await _atClient
          ?.getLocalSecondary()
          ?.putValue(AT_PKAM_PRIVATE_KEY, atSecurityKeys.apkamPrivateKey!);
      logger
          .finer('PkamPrivateKey persist to localSecondary: status $response');
    }
    response = await _atClient?.getLocalSecondary()?.putValue(
        '$AT_ENCRYPTION_PUBLIC_KEY$_atSign',
        atSecurityKeys.defaultEncryptionPublicKey!);
    logger.finer(
        'EncryptionPublicKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_PRIVATE_KEY, atSecurityKeys.defaultEncryptionPrivateKey!);
    logger.finer(
        'EncryptionPrivateKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_SELF_KEY, atSecurityKeys.defaultSelfEncryptionKey!);
    logger
        .finer('SelfEncryptionKey persist to localSecondary: status $response');
  }

  @override
  Future<bool> authenticate({String? enrollmentId}) async {
    // decrypts all the keys in .atKeysFile using the SelfEncryptionKey
    // and stores the keys in a map
    var atSecurityKeys = await _decryptAtKeysFile(
        await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    var pkamPrivateKey = atSecurityKeys.apkamPrivateKey;

    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile &&
        pkamPrivateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Unable to read PkamPrivateKey from provided atKeys file at path: '
          '${atOnboardingPreference.atKeysFilePath}. Please provide a valid atKeys file',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    await _init(atSecurityKeys);
    logger.finer('Authenticating using PKAM');
    try {
      _isPkamAuthenticated =
          (await _atLookUp?.pkamAuthenticate(enrollmentId: enrollmentId))!;
    } on Exception catch (e) {
      logger.severe('Caught exception: $e');
      throw UnAuthenticatedException('Unable to authenticate');
    }
    logger.finer(
        'PKAM auth result: ${_isPkamAuthenticated ? 'success' : 'failed'}');

    if (!_isAtsignOnboarded &&
        _isPkamAuthenticated &&
        atOnboardingPreference.atKeysFilePath != null) {
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

  AtSecurityKeys _decryptAtKeysFile(Map<String, String> jsonData) {
    var securityKeys = AtSecurityKeys();
    String decryptionKey = _getDecryptionKey(jsonData);
    securityKeys.defaultEncryptionPublicKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.encryptionPublicKey]!, decryptionKey);
    securityKeys.defaultEncryptionPrivateKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.encryptionPrivateKey]!, decryptionKey);
    securityKeys.defaultSelfEncryptionKey = decryptionKey;
    securityKeys.apkamPublicKey = EncryptionUtil.decryptValue(
        jsonData[AuthKeyType.pkamPublicKey]!, decryptionKey);
    // pkam private key will not be saved in keyfile if auth mode is sim/any other secure element.
    // decrypt the private key only when auth mode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      securityKeys.apkamPrivateKey = EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey]!, decryptionKey);
    }
    securityKeys.apkamSymmetricKey = jsonData[AuthKeyType.apkamSymmetricKey];
    securityKeys.enrollmentId = jsonData[enrollmentId];
    return securityKeys;
  }

  Future<String> _retrieveEncryptionPublicKey(AtLookUp atLookupImpl) async {
    var lookupVerbBuilder = LookupVerbBuilder()
      ..atKey = 'publickey'
      ..sharedBy = _atSign;
    var lookupResult = await atLookupImpl.executeVerb(lookupVerbBuilder);
    if (lookupResult == null || lookupResult.isEmpty) {
      throw AtEnrollmentException(
          'Unable to lookup encryption public key. Server response is null/empty');
    }
    var defaultEncryptionPublicKey = lookupResult.replaceFirst('data:', '');
    return defaultEncryptionPublicKey;
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
