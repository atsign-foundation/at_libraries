import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

///class containing service that can onboard/activate/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  final String _atSign;
  bool _isPkamAuthenticated = false;
  bool _isAtsignOnboarded = false;
  AtLookupImpl? _atLookup;
  AtClient? _atClient;
  AtSignLogger logger = AtSignLogger('Onboarding Cli');
  AtOnboardingPreference atOnboardingPreference;

  AtOnboardingServiceImpl(this._atSign, this.atOnboardingPreference);

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
      throw UnAuthenticatedException(
          'either of cram secret or qr code containing cram secret not provided');
    } else {
      _atLookup = AtLookupImpl(_atSign, atOnboardingPreference.rootDomain,
          atOnboardingPreference.rootPort);
      _isAtsignOnboarded = (await _atLookup
          ?.authenticate_cram(atOnboardingPreference.cramSecret))!;
      if (_isAtsignOnboarded == true &&
          atOnboardingPreference.downloadPath != null) {
        await _activateAtsign();
        logger.finer('cram authentication successful');
        return true;
      } else {
        throw 'download path not provided';
      }
    }
  }

  ///method to generate/update encryption key-pairs to activate an atsign
  Future<void> _activateAtsign() async {
    RSAKeypair _pkamRsaKeypair;
    RSAKeypair _encryptionKeyPair;
    String _selfEncryptionKey;
    Map atKeysMap;
    //generating pkamKeyPair
    logger.finer('generating pkam keypair');
    _pkamRsaKeypair = generateRsaKeypair();
    //updating pkamPublicKey to remote secondary
    logger.finer('updating pkam public key to remote secondary');
    String updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}\n';
    String? pkamUpdateResult =
        await _atLookup?.executeCommand(updateCommand, auth: false);
    logger.finer('pkam update result: $pkamUpdateResult');
    atOnboardingPreference.privateKey = _pkamRsaKeypair.privateKey.toString();
    //authenticate using pkam to verify insertion of pkamPublicKey
    _isPkamAuthenticated = await authenticate();
    if (_isPkamAuthenticated) {
      //generate selfEncryptionKey
      _selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
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
          .finer('encryption public key update result $encryptKeyUpdateResult');
      //deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
      logger.finer('cram secret delete response : $deleteResponse');
      //mapping encryption keys pairs to their names
      atKeysMap = {
        AuthKeyType.pkamPublicKey: _pkamRsaKeypair.publicKey.toString(),
        AuthKeyType.pkamPrivateKey: _pkamRsaKeypair.privateKey.toString(),
        AuthKeyType.encryptionPublicKey:
            _encryptionKeyPair.publicKey.toString(),
        AuthKeyType.encryptionPrivateKey:
            _encryptionKeyPair.privateKey.toString(),
        AuthKeyType.selfEncryptionKey: _selfEncryptionKey,
        _atSign: _selfEncryptionKey,
      };
      _generateAtKeysFile(atKeysMap);
      await _persistKeysLocalSecondary(atKeysMap, false);
      logger.finer(await getServerStatus().toString());
      logger.finer('----------@sign activated---------');
    } else {
      logger.finer('could not complete pkam authentication');
    }
  }

  ///write newly created encryption keypairs into atKeys file
  Future<void> _generateAtKeysFile(Map atKeysMap) async {
    //encrypting all keys with self encryption key
    atKeysMap[AuthKeyType.pkamPublicKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.pkamPublicKey],
        atKeysMap[AuthKeyType.selfEncryptionKey]);
    atKeysMap[AuthKeyType.pkamPrivateKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.pkamPrivateKey],
        atKeysMap[AuthKeyType.selfEncryptionKey]);
    atKeysMap[AuthKeyType.encryptionPublicKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.encryptionPublicKey],
        atKeysMap[AuthKeyType.selfEncryptionKey]);
    atKeysMap[AuthKeyType.encryptionPrivateKey] = EncryptionUtil.encryptValue(
        atKeysMap[AuthKeyType.encryptionPrivateKey],
        atKeysMap[AuthKeyType.selfEncryptionKey]);
    //generating .atKeys file at path provided in onboardingConfig
    String filePath = path.join(
        atOnboardingPreference.downloadPath!, '${_atSign}_key.atKeys');
    IOSink atKeysFile = File(filePath).openWrite();
    atKeysFile.write(jsonEncode(atKeysMap));
    await atKeysFile.flush();
    await atKeysFile.close();
    logger.finer('atKeys file saved at ${atOnboardingPreference.downloadPath}');
    atOnboardingPreference.atKeysFilePath = filePath;
  }

  ///back-up encryption keys to local secondary
  Future<void> _persistKeysLocalSecondary(Map? _atKeysMap, bool isPkam) async {
    //get decrypt atKeys file data
    if (isPkam) {
      _atKeysMap = await _decryptAtKeysFile(
          await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    }
    //backup keys into local secondary
    if (_atKeysMap != null) {
      bool? response = await _atClient
          ?.getLocalSecondary()
          ?.putValue(AT_PKAM_PUBLIC_KEY, _atKeysMap[AuthKeyType.pkamPublicKey]);
      logger.finer('pkamPublicKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_PKAM_PRIVATE_KEY, _atKeysMap[AuthKeyType.pkamPrivateKey]);
      logger.finer('pkamPrivateKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_ENCRYPTION_PUBLIC_KEY,
          _atKeysMap[AuthKeyType.encryptionPublicKey]);
      logger.finer('encryptionPublicKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_ENCRYPTION_PRIVATE_KEY,
          _atKeysMap[AuthKeyType.encryptionPrivateKey]);
      logger.finer('encryptionPrivateKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AT_ENCRYPTION_SELF_KEY, _atKeysMap[AuthKeyType.selfEncryptionKey]);
      logger.finer('self encryption key persist status $response');
    } else {
      logger.severe('atKeysMap is null');
    }
  }

  @override
  Future<bool> authenticate() async {
    atOnboardingPreference.privateKey ??= _getPkamPrivateKey(
        await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    if (atOnboardingPreference.privateKey == null) {
      throw UnAuthenticatedException(
          'either of private key or .atKeys file not provided');
    } else {
      _atClient ??= await getAtClient();
      _isPkamAuthenticated =
          (await _atLookup?.authenticate(atOnboardingPreference.privateKey))!;
      if (!_isAtsignOnboarded &&
          atOnboardingPreference.atKeysFilePath != null) {
        await _persistKeysLocalSecondary(
            await _decryptAtKeysFile(
                await _readAtKeysFile(atOnboardingPreference.atKeysFilePath)),
            true);
      }
      return _isPkamAuthenticated;
    }
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map?> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath != null) {
      File atKeysFile = File(atKeysFilePath);
      String atAuthData = await atKeysFile.readAsString();
      return jsonDecode(atAuthData);
    } else {
      return null;
    }
  }

  ///method to extract and decrypt pkamPrivateKey from atKeysData
  ///returns pkam_private_key
  String? _getPkamPrivateKey(Map? jsonData) {
    if (jsonData != null) {
      String privateKey = EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey], _getDecryptionKey(jsonData));
      return privateKey;
    } else {
      return null;
    }
  }

  ///method to extract decryption key from atKeysData
  ///returns self_encryption_key
  String _getDecryptionKey(Map? jsonData) {
    return jsonData![AuthKeyType.selfEncryptionKey];
  }

  ///decrypt keys using self_encryption_key
  ///returns map containing decrypted atKeys
  Future<Map> _decryptAtKeysFile(jsonData) async {
    var decryptionKey = _getDecryptionKey(jsonData);
    Map _atKeysMap = {
      AuthKeyType.pkamPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPublicKey], decryptionKey),
      AuthKeyType.pkamPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey], decryptionKey),
      AuthKeyType.encryptionPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPublicKey], decryptionKey),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.encryptionPrivateKey], decryptionKey),
      AuthKeyType.selfEncryptionKey: decryptionKey,
    };
    logger.severe(_atKeysMap[AuthKeyType.encryptionPrivateKey]);
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
    return _atLookup as AtLookUp;
  }
}
