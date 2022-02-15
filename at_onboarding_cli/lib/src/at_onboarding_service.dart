import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart';

///class containing service that can onboard/authenticate @signs
class OnboardingService {
  late String _atSign;
  bool _isPkamAuthenticated = false;
  //late final AtClientManager _atClientManager;
  late final AtLookupImpl? _atLookup;
  late final AtClient _atClient;
  AtSignLogger logger = AtSignLogger('Onboarding CLI');
  AtOnboardingConfig atOnboardingConfig;

  OnboardingService(this._atSign, this.atOnboardingConfig);

  Future<AtClient> createAtClient(
      AtClientPreference? atClientPreference) async {
    atClientPreference ??= AtClientPreference()
      ..privateKey = atOnboardingConfig.pkamPrivateKey ??
          _getPkamPrivateKey(
              await _readAuthData(atOnboardingConfig.atKeysFilePath))
      ..cramSecret = atOnboardingConfig.cramSecret ??
          getSecretFromQr(atOnboardingConfig.qrCodePath)
      ..rootDomain = atOnboardingConfig.rootDomain
      ..rootPort = atOnboardingConfig.rootPort
      ..namespace = atOnboardingConfig.nameSpace
      ..hiveStoragePath = atOnboardingConfig.hiveStoragePath
      ..commitLogPath = atOnboardingConfig.commitLogPath;
    AtClientManager _atClientManager = await AtClientManager.getInstance()
        .setCurrentAtSign(
            _atSign, atOnboardingConfig.nameSpace, atClientPreference);
    _atClient = _atClientManager.atClient;
    _atLookup = _atClient.getRemoteSecondary()?.atLookUp;
    return _atClient;
  }

  ///method to perform one-time cram authentication
  Future<bool> onboard({AtClientPreference? atClientPreference}) async {
    if (_atClient == null) {
      createAtClient(atClientPreference);
    }
    //get cram_secret from either from AtOnboardingConfig or decode it from qr code whichever available
    String? secret = atOnboardingConfig.cramSecret ??
        getSecretFromQr(atOnboardingConfig.qrCodePath!);
    if (secret != null) {
      var isCramSuccessful = await _atLookup?.authenticate_cram(secret);
      if (isCramSuccessful == true) {
        _generateEncryptionKeyPairs();
        logger.finer('cram authentication successful');
        return true;
      }
      return false;
    } else {
      throw Exception(
          'Either of cram secret or qr code containing cram secret not provided');
    }
  }

  ///method to generate/write/update encryption key-pairs
  Future<void> _generateEncryptionKeyPairs() async {
    RSAKeypair _pkamRsaKeypair;
    RSAKeypair _encryptionKeyPair;
    String _selfEncryptionKey;
    Map _atKeysMap;

    logger.finer('generating pkam keypair');
    _pkamRsaKeypair = generateRsaKeypair();
    logger.finer('updating pkam public key to remote secondary');
    var updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}';
    var pkamUpdateResult = _atLookup?.executeCommand(updateCommand);
    logger.finer('pkam update result: $pkamUpdateResult');
    var pkamAuth = await authenticate();
    if (pkamAuth == true) {
      _isPkamAuthenticated = true;
      _selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
      _encryptionKeyPair = generateRsaKeypair();
      updateCommand =
          'update:$AT_ENCRYPTION_PUBLIC_KEY ${_encryptionKeyPair.publicKey}';
      var encryptKeyUpdateResult =
          await _atLookup?.executeCommand(updateCommand);
      logger
          .finer('encryption public key update result $encryptKeyUpdateResult');
      var deleteBuilder = DeleteVerbBuilder()..atKey = AT_CRAM_SECRET;
      var deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
      logger.finer('cram secret delete response : $deleteResponse');
      //mapping encryption keys pairs to their names
      _atKeysMap = {
        "aesPkamPublicKey": EncryptionUtil.encryptValue(
            _pkamRsaKeypair.publicKey.toString(), _selfEncryptionKey),
        "aesPkamPrivateKey": EncryptionUtil.encryptValue(
            _pkamRsaKeypair.privateKey.toString(), _selfEncryptionKey),
        "aes-EncryptPublicKey": EncryptionUtil.encryptValue(
            _encryptionKeyPair.publicKey.toString(), _selfEncryptionKey),
        "aesEncryptPrivateKey": EncryptionUtil.encryptValue(
            _encryptionKeyPair.privateKey.toString(), _selfEncryptionKey),
        "selfEncryptionKey": _selfEncryptionKey,
        _atSign: _selfEncryptionKey,
      };
      //mechanism needed to store files when save location is not provided
      //generating .atKeys file at path provided in onboardingConfig
      IOSink atKeysFile =
          File('${atOnboardingConfig.atKeysDownloadPath}/${_atSign}_key.atKeys')
              .openWrite();
      atKeysFile.write(jsonEncode(_atKeysMap));
    } else {
      logger.finer(
          'could not complete pkam authentication. atKeys file not generated');
    }
  }

  ///method to perform pkam authentication
  Future<bool> authenticate({AtClientPreference? atClientPreference}) async {
    if (_atClient == null) {
      createAtClient(atClientPreference);
    }
    _isPkamAuthenticated = (await _atLookup?.authenticate())!;

    return _isPkamAuthenticated;
  }

  ///method to read and return data from .atKeysFile
  Future<String?> _readAuthData(String? atKeysFilePath) async {
    if (atKeysFilePath != null) {
      File atKeysFile = File(atKeysFilePath);
      String atAuthData = await atKeysFile.readAsString();
      return atAuthData;
    } else {
      return null;
    }
  }

  ///method to extract pkamPrivateKey from atKeysData
  String? _getPkamPrivateKey(String? jsonData) {
    if (jsonData != null) {
      var jsonDecodedData = jsonDecode(jsonData);
      return EncryptionUtil.decryptValue(
          jsonDecodedData[AuthKeyType.PKAM_PRIVATE_KEY_FROM_KEY_FILE],
          _getDecryptionKey(jsonData));
    } else {
      return null;
    }
  }

  ///method to extract decryption key from atKeysData
  String _getDecryptionKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    var key = jsonDecodedData[AuthKeyType.SELF_ENCRYPTION_KEY_FROM_FILE];
    return key;
  }

  AtLookupImpl? getAtLookup() {
    return _atLookup;
  }

  RSAKeypair generateRsaKeypair() {
    return RSAKeypair.fromRandom();
  }

  static String generateAESKey() {
    var aesKey = AES(Key.fromSecureRandom(32));
    var keyString = aesKey.key.base64;
    return keyString;
  }

  ///extracts cram secret from qrCode
  dynamic getSecretFromQr(String? path) {
    if (path != null) {
      var image = decodePng(File(path).readAsBytesSync());
      LuminanceSource source = RGBLuminanceSource(image!.width, image.height,
          image.getBytes(format: Format.abgr).buffer.asInt32List());
      var bitmap = BinaryBitmap(HybridBinarizer(source));
      var result = QRCodeReader().decode(bitmap);
      String secret = result.text.split(':')[1];
      return secret;
    } else {
      return null;
    }
  }
}
