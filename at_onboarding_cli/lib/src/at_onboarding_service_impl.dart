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
    if (atOnboardingPreference.downloadPath == null) {
      throw AtClientException.message('Download path not provided',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    _atLookup = AtLookupImpl(_atSign, atOnboardingPreference.rootDomain,
        atOnboardingPreference.rootPort);
    _isAtsignOnboarded = (await _atLookup
        ?.authenticate_cram(atOnboardingPreference.cramSecret))!;
    if (_isAtsignOnboarded) {
      await _activateAtsign();
      logger.info('Cram authentication successful');
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
    //updating pkamPublicKey to remote secondary
    logger.finer('Updating PkamPublicKey to remote secondary');
    String updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}\n';
    String? pkamUpdateResult =
        await _atLookup?.executeCommand(updateCommand, auth: false);
    logger.finer('PkamPublicKey update result: $pkamUpdateResult');
    atOnboardingPreference.privateKey = _pkamRsaKeypair.privateKey.toString();
    //authenticate using pkam to verify insertion of pkamPublicKey
    _isPkamAuthenticated = await authenticate();

    if (_isPkamAuthenticated) {
      //generate selfEncryptionKey
      _selfEncryptionKey = generateAESKey();
      logger.info('Generating encryption keypair');
      //generate user encryption keypair
      _encryptionKeyPair = generateRsaKeypair();
      //update user encryption public key
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = _encryptionKeyPair.publicKey.toString()
        ..sharedBy = _atSign;
      String? encryptKeyUpdateResult =
          await _atLookup?.executeVerb(updateBuilder);
      logger
          .finer('Encryption public key update result $encryptKeyUpdateResult');
      //deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
      logger.finer('Cram secret delete response : $deleteResponse');
      //mapping encryption keys pairs to their names
      atKeysMap = <String, String>{
        AuthKeyType.pkamPublicKey: _pkamRsaKeypair.publicKey.toString(),
        AuthKeyType.pkamPrivateKey: _pkamRsaKeypair.privateKey.toString(),
        AuthKeyType.encryptionPublicKey:
            _encryptionKeyPair.publicKey.toString(),
        AuthKeyType.encryptionPrivateKey:
            _encryptionKeyPair.privateKey.toString(),
        AuthKeyType.selfEncryptionKey: _selfEncryptionKey,
        _atSign: _selfEncryptionKey,
      };
      await _generateAtKeysFile(atKeysMap);
      await _persistKeysLocalSecondary(atKeysMap, false);
      //displays status of the atsign
      logger.finer(await getServerStatus());
      logger.info('----------@sign activated---------');
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
    //generating .atKeys file at path provided in onboardingConfig
    atOnboardingPreference.atKeysFilePath = path.join(
        atOnboardingPreference.downloadPath!, '${_atSign}_key.atKeys');
    IOSink atKeysFile =
        File(atOnboardingPreference.atKeysFilePath!).openWrite();
    atKeysFile.write(jsonEncode(atKeysMap));
    await atKeysFile.flush();
    await atKeysFile.close();
    logger
        .info('atKeys file saved at ${atOnboardingPreference.atKeysFilePath}');
  }

  ///back-up encryption keys to local secondary
  Future<void> _persistKeysLocalSecondary(
      Map<String, String>? _atKeysMap, bool isPkam) async {
    //when authenticating keys need to be fetched from atKeys file
    if (isPkam) {
      _atKeysMap = await _decryptAtKeysFile(
          (await _readAtKeysFile(atOnboardingPreference.atKeysFilePath))!);
    }
    //backup keys into local secondary
    if (_atKeysMap != null) {
      bool? response = await _atClient?.getLocalSecondary()?.putValue(
          AT_PKAM_PUBLIC_KEY, _atKeysMap[AuthKeyType.pkamPublicKey]!);
      logger.finer('PkamPublicKey persist to localSecondary: status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_PKAM_PRIVATE_KEY, _atKeysMap[AuthKeyType.pkamPrivateKey]!);
      logger
          .finer('PkamPrivateKey persist to localSecondary: status $response');
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
    } else {
      logger.severe('atKeysMap is null');
    }
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
        await _persistKeysLocalSecondary(
            await _decryptAtKeysFile((await _readAtKeysFile(
                atOnboardingPreference.atKeysFilePath))!),
            true);
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

  @override
  AtLookUp getAtLookup() {
    return _atLookup!;
  }
}
