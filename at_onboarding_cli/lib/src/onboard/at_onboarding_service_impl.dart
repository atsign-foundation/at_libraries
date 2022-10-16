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

///class containing service that can onboard/activate/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  late final String _atSign;
  bool _isPkamAuthenticated = false;
  bool _isAtsignOnboarded = false;
  AtLookupImpl? _atLookup;
  AtClient? _atClient;
  AtSignLogger logger = AtSignLogger('OnboardingCli');
  AtOnboardingPreference atOnboardingPreference;

  AtOnboardingServiceImpl(atsign, this.atOnboardingPreference) {
    _atSign = AtUtils.formatAtSign(atsign)!;
    //performs atSign format checks on the atSign
    AtUtils.fixAtSign(_atSign);
  }

  @override
  Future<AtClient?> getAtClient() async {
    if (_atClient == null) {
      AtClientManager _atClientManager = AtClientManager.getInstance();
      await _atClientManager.setCurrentAtSign(
          _atSign, atOnboardingPreference.namespace, atOnboardingPreference);
      _atLookup = _atClientManager.atClient.getRemoteSecondary()?.atLookUp;
      return _atClientManager.atClient;
    }
    return _atClient;
  }

  @override
  Future<bool> onboard() async {
    //get cram_secret from either from AtOnboardingConfig or decode it from qr code whichever available
    atOnboardingPreference.cramSecret ??=
        _getSecretFromQr(atOnboardingPreference.qrCodePath);

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
    _atLookup = AtLookupImpl(_atSign, atOnboardingPreference.rootDomain,
        atOnboardingPreference.rootPort);
    //check and wait till secondary exists
    await _waitUntilSecondaryExists();
    //authenticate into secondary using cram secret
    _isAtsignOnboarded = (await _atLookup
        ?.authenticate_cram(atOnboardingPreference.cramSecret))!;
    logger.info('Cram authentication status: $_isAtsignOnboarded');

    if (_isAtsignOnboarded) {
      await _activateAtsign();
    }

    return _isAtsignOnboarded;
  }

  ///method to generate/update encryption key-pairs to activate an atsign
  Future<void> _activateAtsign() async {
    RSAKeypair _pkamRsaKeypair;
    RSAKeypair _encryptionKeyPair;
    String _selfEncryptionKey;
    Map<String, String> atKeysMap;

    //generating pkamKeyPair
    logger.info('Generating pkam keypair');
    _pkamRsaKeypair = generateRsaKeypair();

    //generate user encryption keypair
    logger.info('Generating encryption keypair');
    _encryptionKeyPair = generateRsaKeypair();

    //generate selfEncryptionKey
    _selfEncryptionKey = generateAESKey();

    //mapping encryption keys pairs to their names
    atKeysMap = <String, String>{
      AuthKeyType.pkamPublicKey: _pkamRsaKeypair.publicKey.toString(),
      AuthKeyType.pkamPrivateKey: _pkamRsaKeypair.privateKey.toString(),
      AuthKeyType.encryptionPublicKey: _encryptionKeyPair.publicKey.toString(),
      AuthKeyType.encryptionPrivateKey:
          _encryptionKeyPair.privateKey.toString(),
      AuthKeyType.selfEncryptionKey: _selfEncryptionKey,
      _atSign: _selfEncryptionKey,
    };
    //generate .atKeys file
    await _generateAtKeysFile(atKeysMap);

    //updating pkamPublicKey to remote secondary
    logger.finer('Updating PkamPublicKey to remote secondary');
    String updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}\n';
    String? pkamUpdateResult =
        await _atLookup?.executeCommand(updateCommand, auth: false);
    logger.info('PkamPublicKey update result: $pkamUpdateResult');
    atOnboardingPreference.privateKey = _pkamRsaKeypair.privateKey.toString();

    //authenticate using pkam to verify insertion of pkamPublicKey
    _isPkamAuthenticated =
        (await _atLookup?.authenticate(atOnboardingPreference.privateKey))!;

    if (_isPkamAuthenticated) {
      //update user encryption public key to remote secondary
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = _encryptionKeyPair.publicKey.toString()
        ..sharedBy = _atSign;
      String? encryptKeyUpdateResult =
          await _atLookup?.executeVerb(updateBuilder);
      logger
          .info('Encryption public key update result $encryptKeyUpdateResult');
      //deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
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
    atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.pkamPublicKey]!,
        atKeysMap[AuthKeyType.selfEncryptionKey]!);
    atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.pkamPrivateKey]!,
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
    //file is created with whichever name provided as atKeysFilePath(even if filename does not match standary atKeys file name convention)
    IOSink atKeysFile = File(atOnboardingPreference.downloadPath ??
            atOnboardingPreference.atKeysFilePath!)
        .openWrite();

    //generating .atKeys file at path provided in onboardingConfig
    atKeysFile.write(jsonEncode(atKeysMap));
    await atKeysFile.flush();
    await atKeysFile.close();
    logger.info(
        'atKeys file saved at ${atOnboardingPreference.downloadPath ?? atOnboardingPreference.atKeysFilePath}');
  }

  ///back-up encryption keys to local secondary
  Future<void> _persistKeysLocalSecondary() async {
    //when authenticating keys need to be fetched from atKeys file
    Map<String, String> _atKeysMap = await _decryptAtKeysFile(
        (await _readAtKeysFile(atOnboardingPreference.atKeysFilePath))!);
    //backup keys into local secondary
    bool? response = await _atClient
        ?.getLocalSecondary()
        ?.putValue(AT_PKAM_PUBLIC_KEY, _atKeysMap[AuthKeyType.pkamPublicKey]!);
    logger.finer('PkamPublicKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_PKAM_PRIVATE_KEY, _atKeysMap[AuthKeyType.pkamPrivateKey]!);
    logger.finer('PkamPrivateKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        '$AT_ENCRYPTION_PUBLIC_KEY$_atSign',
        _atKeysMap[AuthKeyType.encryptionPublicKey]!);
    logger.finer(
        'EncryptionPublicKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_PRIVATE_KEY,
        _atKeysMap[AuthKeyType.encryptionPrivateKey]!);
    logger.finer(
        'EncryptionPrivateKey persist to localSecondary: status $response');
    response = await _atClient?.getLocalSecondary()?.putValue(
        AT_ENCRYPTION_SELF_KEY, _atKeysMap[AuthKeyType.selfEncryptionKey]!);
    logger.finer(
        'Self encryption key persist to localSecondary: status $response');
  }

  @override
  Future<bool> authenticate() async {
    atOnboardingPreference.privateKey ??= _getPkamPrivateKey(
        await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));

    if (atOnboardingPreference.privateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Either of private key or .atKeys file not provided in preferences',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    } else {
      _atClient ??= await getAtClient();
      _isPkamAuthenticated =
          await _atLookup?.authenticate(atOnboardingPreference.privateKey) ??
              false;
      if (!_isAtsignOnboarded &&
          atOnboardingPreference.atKeysFilePath != null) {
        await _persistKeysLocalSecondary();
      }
      return _isPkamAuthenticated;
    }
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map<String, String>?> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath != null) {
      String atAuthData = await File(atKeysFilePath).readAsString();
      Map<String, String> jsonData = <String, String>{};
      json.decode(atAuthData).forEach((String key, dynamic value) {
        jsonData[key] = value.toString();
      });
      return jsonData;
    } else {
      return null;
    }
  }

  ///method to extract and decrypt pkamPrivateKey from atKeysData
  ///returns pkam_private_key
  String? _getPkamPrivateKey(Map<String, String>? jsonData) => jsonData == null
      ? null
      : EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey]!, _getDecryptionKey(jsonData));

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
    Map<String, String> _atKeysMap = <String, String>{
      AuthKeyType.pkamPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPublicKey]!, decryptionKey),
      AuthKeyType.pkamPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey]!, decryptionKey),
      AuthKeyType.encryptionPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPublicKey]!, decryptionKey),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPrivateKey]!, decryptionKey),
      AuthKeyType.selfEncryptionKey: decryptionKey,
    };
    return _atKeysMap;
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
  String? _getSecretFromQr(String? path) {
    if (path != null) {
      Image? image = decodePng(File(path).readAsBytesSync());
      LuminanceSource source = RGBLuminanceSource(image!.width, image.height,
          image.getBytes(format: Format.abgr).buffer.asInt32List());
      BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      Result result = QRCodeReader().decode(bitmap);
      String secret = result.text.split(':')[1];
      return secret;
    } else {
      return null;
    }
  }

  ///Method to check if secondary belonging to [_atSign] exists
  ///If not, wait until secondary is created
  Future<void> _waitUntilSecondaryExists() async {
    final maxRetries = 50;
    int _retryCount = 0;
    SecondaryAddress? _secondaryAddress;
    SecureSocket? secureSocket;

    while (_retryCount < maxRetries && _secondaryAddress == null) {
      logger.finer('retrying find secondary.......$_retryCount/$maxRetries');
      try {
        _secondaryAddress =
            await _atLookup?.secondaryAddressFinder.findSecondary(_atSign);
      } on Exception catch (e) {
        logger.finer(e);
      }
      _retryCount++;
    }
    //resetting retry counter to be used for different operation
    _retryCount = 0;
    while (secureSocket == null && _retryCount < maxRetries) {
      logger.finer('retrying connect secondary.......$_retryCount/$maxRetries');
      try {
        secureSocket = await SecureSocket.connect(
            _secondaryAddress!.host, _secondaryAddress.port);
      } on Exception catch (e) {
        logger.finer(e);
      }
    }
  }

  @override
  Future<void> close() async {
    await _atLookup?.close();
    _atClient = null;
    logger.severe('Killing current instance of at_onboarding_cli');
    exit(0);
  }

  @override
  AtLookUp getAtLookup() {
    return _atLookup!;
  }
}