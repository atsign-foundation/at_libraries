// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_utils/at_utils.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;
import 'package:at_chops/at_chops.dart';

///class containing service that can onboard/activate/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  late final String _atSign;
  bool _isPkamAuthenticated = false;
  bool _isAtsignOnboarded = false;
  AtSignLogger logger = AtSignLogger('OnboardingCli');
  AtOnboardingPreference atOnboardingPreference;
  AtClient? _atClient;
  AtLookUp? _atLookUp;

  AtOnboardingServiceImpl(atsign, this.atOnboardingPreference) {
    //performs atSign format checks on the atSign
    _atSign = AtUtils.formatAtSign(AtUtils.fixAtSign(atsign))!;
  }

  Future<void> _init(AtChops atChops) async {
    AtClientManager atClientManager = AtClientManager.getInstance();
    await atClientManager.setCurrentAtSign(
        _atSign, atOnboardingPreference.namespace, atOnboardingPreference,
        atChops: atChops);
    // ??= to support mocking
    _atLookUp ??= atClientManager.atClient.getRemoteSecondary()?.atLookUp;
    _atClient ??= atClientManager.atClient;
  }

  @override
  @Deprecated('Use getter')
  Future<AtClient?> getAtClient() async {
    return _atClient;
  }

  @override
  Future<bool> onboard() async {
    //get cram_secret from either from AtOnboardingConfig or decode it from qr code whichever available
    atOnboardingPreference.cramSecret ??=
        getSecretFromQr(atOnboardingPreference.qrCodePath);

    if (atOnboardingPreference.cramSecret == null) {
      throw AtClientException.message(
          'Either of cram secret or qr code containing cram secret not provided',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    if (atOnboardingPreference.downloadPath == null &&
        atOnboardingPreference.atKeysFilePath == null) {
      throw AtClientException.message('Download path not provided',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    // cram auth doesn't use at_chops.So create at_lookup here.
    AtLookupImpl atLookUpImpl = AtLookupImpl(_atSign,
        atOnboardingPreference.rootDomain, atOnboardingPreference.rootPort);
    try {
      //check and wait till secondary exists
      await _waitUntilSecondaryCreated(atLookUpImpl);
      //authenticate into secondary using cram secret
      _isAtsignOnboarded = (await atLookUpImpl
          .authenticate_cram(atOnboardingPreference.cramSecret));

      logger.info('Cram authentication status: $_isAtsignOnboarded');

      // if (_isAtsignOnboarded) {
      //   await _activateAtsign(atLookUpImpl);
      // }
    } finally {
      await atLookUpImpl.close();
    }

    return _isAtsignOnboarded;
  }

  ///method to generate/update encryption key-pairs to activate an atsign
  Future<void> _activateAtsign(AtLookupImpl atLookUpImpl) async {
    RSAKeypair pkamRsaKeypair;
    RSAKeypair encryptionKeyPair;
    String selfEncryptionKey;
    Map<String, String> atKeysMap;

    //generate user encryption keypair
    logger.info('Generating encryption keypair');
    encryptionKeyPair = generateRsaKeypair();

    //generate selfEncryptionKey
    selfEncryptionKey = generateAESKey();

    stdout.writeln(
        '[Information] Generating your encryption keys and .atKeys file\n');
    //mapping encryption keys pairs to their names
    atKeysMap = <String, String>{
      AuthKeyType.encryptionPublicKey: encryptionKeyPair.publicKey.toString(),
      AuthKeyType.encryptionPrivateKey: encryptionKeyPair.privateKey.toString(),
      AuthKeyType.selfEncryptionKey: selfEncryptionKey,
      _atSign: selfEncryptionKey,
    };
    var pkamPublicKey;
    //generating pkamKeyPair only if authMode is keysFile
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      logger.info('Generating pkam keypair');
      pkamRsaKeypair = generateRsaKeypair();
      atKeysMap[AuthKeyType.pkamPublicKey] =
          pkamRsaKeypair.publicKey.toString();
      atKeysMap[AuthKeyType.pkamPrivateKey] =
          pkamRsaKeypair.privateKey.toString();
      pkamPublicKey = pkamRsaKeypair.publicKey.toString();
    } else if (atOnboardingPreference.authMode == PkamAuthMode.sim) {
      pkamPublicKey =
          atChops!.readPublicKey(atOnboardingPreference.publicKeyId!);
      logger.info('pkam  public key from sim: $pkamPublicKey');
      atKeysMap[AuthKeyType.pkamPublicKey] = pkamPublicKey;
      // encryption key pair and self encryption symmetric key are not available to injected at_chops. Set it here
      atChops!.atChopsKeys.atEncryptionKeyPair = AtEncryptionKeyPair.create(
          encryptionKeyPair.publicKey.toString(),
          encryptionKeyPair.privateKey.toString());
      atChops!.atChopsKeys.symmetricKey = AESKey(selfEncryptionKey);
    }
    //generate .atKeys file
    await _generateAtKeysFile(atKeysMap);

    //updating pkamPublicKey to remote secondary
    logger.finer('Updating PkamPublicKey to remote secondary');
    String updateCommand = 'update:$AT_PKAM_PUBLIC_KEY ${pkamPublicKey}\n';
    String? pkamUpdateResult =
        await atLookUpImpl.executeCommand(updateCommand, auth: false);
    logger.info('PkamPublicKey update result: $pkamUpdateResult');

    //authenticate using pkam to verify insertion of pkamPublicKey
    _isPkamAuthenticated = (await atLookUpImpl
        .authenticate(atKeysMap[AuthKeyType.pkamPrivateKey]));

    if (_isPkamAuthenticated) {
      //update user encryption public key to remote secondary
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = encryptionKeyPair.publicKey.toString()
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
      logger.info('----------atSign activated---------');
    } else {
      throw AtClientException.message('Pkam Authentication Failed');
    }
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

    if (atOnboardingPreference.downloadPath != null) {
      //create directory at provided path if one does not exist already
      if (!(await Directory(atOnboardingPreference.downloadPath!).exists())) {
        await Directory(atOnboardingPreference.downloadPath!).create();
      }
      //construct download path to match standard atKeys file name convention
      atOnboardingPreference.downloadPath = path.join(
          atOnboardingPreference.downloadPath!, '${_atSign}_key.atKeys');
    } else {
      //if atKeysFilePath points to a directory and not a file, create a file in the provided directory
      if (await Directory(atOnboardingPreference.atKeysFilePath!).exists()) {
        atOnboardingPreference.atKeysFilePath = path.join(
            atOnboardingPreference.atKeysFilePath!, '${_atSign}_key.atKeys');
      }

      //if provided file is not of format .atKeys, append .atKeys to filename
      if (!atOnboardingPreference.atKeysFilePath!.endsWith('.atKeys')) {
        throw AtClientException.message(
            'atKeysFilePath provided should be of format .atKeys');
      }
    }
    //note: in case atKeysFilePath is provided instead of downloadPath;
    //file is created with whichever name provided as atKeysFilePath(even if filename does not match standard atKeys file name convention)
    IOSink atKeysFile = File(atOnboardingPreference.downloadPath ??
            atOnboardingPreference.atKeysFilePath!)
        .openWrite();

    //generating .atKeys file at path provided in onboardingConfig
    atKeysFile.write(jsonEncode(atKeysMap));
    await atKeysFile.flush();
    await atKeysFile.close();
    logger.info(
        'atKeys file saved at ${atOnboardingPreference.downloadPath ?? atOnboardingPreference.atKeysFilePath}');
    stdout.writeln(
        '[Success] Your .atKeys file saved at ${atOnboardingPreference.downloadPath ?? atOnboardingPreference.atKeysFilePath}\n');
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
    atChops ??= _createAtChops(atKeysFileDataMap);
    await _init(atChops!);
    _atLookUp!.atChops = atChops;
    _atClient!.atChops = atChops;
    _atClient!.getPreferences()!.useAtChops = true;
    _isPkamAuthenticated = (await _atLookUp?.pkamAuthenticate(
        signingAlgoType: atOnboardingPreference.signingAlgoType,
        hashingAlgoType: atOnboardingPreference.hashingAlgoType))!;

    if (!_isAtsignOnboarded && atOnboardingPreference.atKeysFilePath != null) {
      await _persistKeysLocalSecondary();
    }
    return _isPkamAuthenticated;
  }

  AtChops _createAtChops(Map<String, String> atKeysFileDataMap) {
    final atEncryptionKeyPair = AtEncryptionKeyPair.create(
        atKeysFileDataMap[AuthKeyType.encryptionPublicKey]!,
        atKeysFileDataMap[AuthKeyType.encryptionPrivateKey]!);
    final atPkamKeyPair = AtPkamKeyPair.create(
        atKeysFileDataMap[AuthKeyType.pkamPublicKey]!,
        atKeysFileDataMap[AuthKeyType.pkamPrivateKey]!);
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
    if (atOnboardingPreference.authMode == PkamAuthMode.keysFile) {
      atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPublicKey]!, decryptionKey);
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
      print('exception while getting secret from QR code: $e');
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
      } on Exception catch (e) {
        logger.finer(e);
      }
      retryCount++;
    }

    if (secondaryAddress == null) {
      logger.severe(
          'Could not find secondary address for $_atSign after $retryCount retries');
      exit(1);
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
      } on Exception catch (e) {
        logger.finer(e);
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
    exit(0);
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
