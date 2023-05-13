// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_utils/at_utils.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_onboarding_cli/src/factory/service_factories.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

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

  Future<void> _init(Map<String, String> atKeysFileDataMap) async {
    atChops ??= _createAtChops(atKeysFileDataMap);
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
    // TODO uncomment this code after isOnboarded is implemented
    // if(isOnboarded()) {
    //   return true;
    // }

    // get cram_secret from either from AtOnboardingPreference
    // or fetch from the registrar using verification code sent to email
    atOnboardingPreference.cramSecret ??= await OnboardingUtil()
        .getCramUsingOtp(_atSign, atOnboardingPreference.registrarUrl);

    if (atOnboardingPreference.cramSecret == null) {
      logger.info('Root Server address is ${atOnboardingPreference.rootDomain}:'
          '${atOnboardingPreference.rootPort}');
      throw AtClientException.message(
          'Could not fetch cram secret for \'$_atSign\' from '
          '\'${atOnboardingPreference.registrarUrl}\'');
    }

    // cram auth doesn't use at_chops. So create at_lookup here.
    AtLookupImpl atLookUpImpl = AtLookupImpl(_atSign,
        atOnboardingPreference.rootDomain, atOnboardingPreference.rootPort);
    try {
      //check and wait till secondary exists
      await _waitUntilSecondaryCreated(atLookUpImpl);
      //authenticate into secondary using cram secret
      _isAtsignOnboarded = (await atLookUpImpl
          .authenticate_cram(atOnboardingPreference.cramSecret));

      logger.info('Cram authentication status: $_isAtsignOnboarded');

      if (_isAtsignOnboarded) {
        await _activateAtsign(atLookUpImpl);
      }
    } finally {
      await atLookUpImpl.close();
    }
    return _isAtsignOnboarded;
  }

  ///method to generate/update encryption key-pairs to activate an atsign
  Future<void> _activateAtsign(AtLookupImpl atLookUpImpl) async {
    //1. Generate pkam key pair(if authMode is keyFile), encryption key pair and self encryption key
    Map<String, String> atKeysMap = await _generateKeyPairs();

    //2. generate .atKeys file using a copy of atKeysMap
    await _generateAtKeysFile(Map.of(atKeysMap));

    //3. Updating pkamPublicKey to remote secondary
    logger.finer('Updating PkamPublicKey to remote secondary');
    final pkamPublicKey = atKeysMap[AuthKeyType.pkamPublicKey];
    String updateCommand = 'update:$AT_PKAM_PUBLIC_KEY $pkamPublicKey\n';
    String? pkamUpdateResult =
        await atLookUpImpl.executeCommand(updateCommand, auth: false);
    logger.info('PkamPublicKey update result: $pkamUpdateResult');

    //4. initialise atClient and atChops and attempt a pkam auth to server.
    await _init(atKeysMap);
    _isPkamAuthenticated = (await _atLookUp?.pkamAuthenticate())!;

    //5. If Pkam auth is success, update encryption public key to secondary and delete cram key from server
    if (_isPkamAuthenticated) {
      final encryptionPublicKey = atKeysMap[AuthKeyType.encryptionPublicKey];
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = encryptionPublicKey
        ..sharedBy = _atSign;
      String? encryptKeyUpdateResult =
          await atLookUpImpl.executeVerb(updateBuilder);
      logger
          .info('Encryption public key update result $encryptKeyUpdateResult');
      //deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await atLookUpImpl.executeVerb(deleteBuilder);
      logger.info('Cram secret delete response : $deleteResponse');
      //displays status of the atsign
      logger.finer(await getServerStatus());
      stdout.writeln('[Success]----------atSign activated---------');
    } else {
      throw AtClientException.message('Pkam Authentication Failed');
    }
  }

  Future<Map<String, String>> _generateKeyPairs() async {
    //generate user encryption keypair
    logger.info('Generating encryption keypair');
    var encryptionKeyPair = generateRsaKeypair();

    //generate selfEncryptionKey
    var selfEncryptionKey = generateAESKey();

    stdout.writeln(
        '[Information] Generating your encryption keys and .atKeys file\n');
    //mapping encryption keys pairs to their names
    Map<String, String> atKeysMap = <String, String>{};
    String pkamPublicKey;
    //generating pkamKeyPair only if authMode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      logger.info('Generating pkam keypair');
      var pkamRsaKeypair = generateRsaKeypair();
      atKeysMap[AuthKeyType.pkamPublicKey] =
          pkamRsaKeypair.publicKey.toString();
      atKeysMap[AuthKeyType.pkamPrivateKey] =
          pkamRsaKeypair.privateKey.toString();
      pkamPublicKey = pkamRsaKeypair.publicKey.toString();
    } else if (atOnboardingPreference.authMode == PkamAuthMode.sim) {
      // get the public key from secure element
      pkamPublicKey =
          atChops!.readPublicKey(atOnboardingPreference.publicKeyId!);
      logger.info('pkam  public key from sim: $pkamPublicKey');
      atKeysMap[AuthKeyType.pkamPublicKey] = pkamPublicKey;
      // encryption key pair and self encryption symmetric key
      // are not available to injected at_chops. Set it here
      atChops!.atChopsKeys.atEncryptionKeyPair = AtEncryptionKeyPair.create(
          encryptionKeyPair.publicKey.toString(),
          encryptionKeyPair.privateKey.toString());
      atChops!.atChopsKeys.symmetricKey = AESKey(selfEncryptionKey);
    }
    //Standard order of an atKeys file is ->
    // pkam keypair -> encryption keypair -> selfEncryption key ->
    // @sign: selfEncryptionKey[self encryption key again]
    // note: "->" stands for "followed by"
    atKeysMap[AuthKeyType.encryptionPublicKey] =
        encryptionKeyPair.publicKey.toString();
    atKeysMap[AuthKeyType.encryptionPrivateKey] =
        encryptionKeyPair.privateKey.toString();
    atKeysMap[AuthKeyType.selfEncryptionKey] = selfEncryptionKey;
    atKeysMap[_atSign] = selfEncryptionKey;

    return atKeysMap;
  }

  ///write newly created encryption keypairs into atKeys file
  Future<void> _generateAtKeysFile(Map<String, String> atKeysMap) async {
    //encrypting all keys with self encryption key
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
          atKeysMap[AuthKeyType.pkamPrivateKey]!,
          atKeysMap[AuthKeyType.selfEncryptionKey]!);
    }
    atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.pkamPublicKey]!,
        atKeysMap[AuthKeyType.selfEncryptionKey]!);
    atKeysMap[AuthKeyType.encryptionPublicKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.encryptionPublicKey]!,
        atKeysMap[AuthKeyType.selfEncryptionKey]!);
    atKeysMap[AuthKeyType.encryptionPrivateKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.encryptionPrivateKey]!,
        atKeysMap[AuthKeyType.selfEncryptionKey]!);

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
    logger.finer(
        'Self encryption key persist to localSecondary: status $response');
  }

  @override
  Future<bool> authenticate() async {
    var atKeysFileDataMap = await _decryptAtKeysFile(
        await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    var pkamPrivateKey = atKeysFileDataMap[AuthKeyType.pkamPrivateKey];

    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile &&
        pkamPrivateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Unable to read pkam private key from provided .atKeys path: ${atOnboardingPreference.atKeysFilePath}',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    await _init(atKeysFileDataMap);
    logger.finer('pkam auth');
    _isPkamAuthenticated = (await _atLookUp?.pkamAuthenticate())!;
    logger.finer('pkam auth result: $_isPkamAuthenticated');

    if (!_isAtsignOnboarded && atOnboardingPreference.atKeysFilePath != null) {
      await _persistKeysLocalSecondary();
    }
    return _isPkamAuthenticated;
  }

  AtChops _createAtChops(Map<String, String> atKeysDataMap) {
    final atEncryptionKeyPair = AtEncryptionKeyPair.create(
        atKeysDataMap[AuthKeyType.encryptionPublicKey]!,
        atKeysDataMap[AuthKeyType.encryptionPrivateKey]!);
    final atPkamKeyPair = AtPkamKeyPair.create(
        atKeysDataMap[AuthKeyType.pkamPublicKey]!,
        atKeysDataMap[AuthKeyType.pkamPrivateKey]!);
    final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
    return AtChopsImpl(atChopsKeys);
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map<String, String>> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath == null || atKeysFilePath.isEmpty) {
      throw AtClientException.message(
          'atKeys filePath is null or empty. atKeysFile needs to be provided');
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

  ///extracts cram secret from qrCode
  @Deprecated('qr_code based cram authentication not supported anymore')
  static String? getSecretFromQr(String? path) {
    if (path == null) {
      return null;
    }
    try {
      Image? image = decodePng(File(path).readAsBytesSync());
      LuminanceSource source = RGBLuminanceSource(image!.width, image.height,
          image.getBytes(format: Format.abgr).buffer.asInt32List());
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
      await Future.delayed(Duration(seconds: 3));
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
    logger.finer('secondaryAddress ** $secondaryAddress');
    if (secondaryAddress == null) {
      throw SecondaryNotFoundException('Could not find secondary address for '
          '$_atSign after $retryCount retries');
    }
    //resetting retry counter to be used for different operation
    retryCount = 1;

    while (!connectionFlag && retryCount <= maxRetries) {
      await Future.delayed(Duration(seconds: 3));
      logger.finer('retrying connect secondary.......$retryCount/$maxRetries');
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
    _atClient = null;
    logger.info('Closing current instance of at_onboarding_cli');
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

  @override
  Future<bool> isOnboarded() async {
    // #TODO implement once AtClient offline access feature is complete.
    // https://github.com/atsign-foundation/at_client_sdk/issues/915
    throw UnimplementedError();
  }
}
