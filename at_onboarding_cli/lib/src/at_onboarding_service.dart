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
  String _atSign;
  bool _isPkamAuthenticated = false;
  AtLookupImpl? _atLookup;
  AtClient? _atClient;
  AtSignLogger logger = AtSignLogger('Onboarding CLI');
  AtOnboardingConfig atOnboardingConfig;

  AtClient? get atClient => _atClient;
  AtLookupImpl? get atLookup => _atLookup;

  OnboardingService(this._atSign, this.atOnboardingConfig);

  ///creates instance of [AtClient] using either of [AtClientPreference] or [AtOnboardingConfig]
  Future<AtClient?> createAtClient() async {
    AtClientManager _atClientManager = AtClientManager.getInstance();
    await _atClientManager.setCurrentAtSign(
            _atSign, atOnboardingConfig.namespace, atOnboardingConfig);
    var atClient = _atClientManager.atClient;
    _atLookup = atClient.getRemoteSecondary()?.atLookUp;
    return atClient;
  }

  ///method to perform one-time cram authentication
  Future<bool> onboard() async {
    //get cram_secret from either from AtOnboardingConfig or decode it from qr code whichever available
    var secret = atOnboardingConfig.privateKey ?? getSecretFromQr(atOnboardingConfig.qrCodePath);
    //logger.severe(secret);
    _atLookup = AtLookupImpl(_atSign, atOnboardingConfig.rootDomain, atOnboardingConfig.rootPort);
    bool? isCramSuccessful = await _atLookup?.authenticate_cram(secret);
    //logger.severe('cram status $isCramSuccessful');
    if (isCramSuccessful == true) {
      await  _generateEncryptionKeyPairs();
      logger.finer('cram authentication successful');
      return true;
    }
    return false;
  }

  ///method to generate/write/update encryption key-pairs
  Future<void> _generateEncryptionKeyPairs() async {
    RSAKeypair _pkamRsaKeypair;
    RSAKeypair _encryptionKeyPair;
    String _selfEncryptionKey;
    Map _atKeysMap;

    logger.finer('generating pkam keypair');
    //creating pkamKeyPair
    _pkamRsaKeypair = generateRsaKeypair();
    logger.finer('updating pkam public key to remote secondary');
    // var updateCommand =
    //     'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}';
    //updating pkamPublicKey to remote secondary
    // var pkamUpdateResult = await _atLookup?.executeCommand(updateCommand, auth: false);
    var pkamUpdateResult = await _atLookup?.update(AT_PKAM_PUBLIC_KEY, _pkamRsaKeypair.publicKey.toString());
    logger.finer('pkam update result: $pkamUpdateResult');
    atOnboardingConfig.privateKey = _pkamRsaKeypair.privateKey.toString();
    logger.severe(await _atLookup?.llookup(AT_PKAM_PUBLIC_KEY));
    var pkamAuth = await authenticate();
    if (pkamAuth == true) {
      _isPkamAuthenticated = true;
      //generate selfEncryptionKey
      _selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
      //generate user encryption keypair
      _encryptionKeyPair = generateRsaKeypair();
      // var updateCommand =
      //     'update:$AT_ENCRYPTION_PUBLIC_KEY ${_encryptionKeyPair.publicKey}';
      //update user encryption public key to remote secondary
      var encryptKeyUpdateResult =
          await _atLookup?.update(AT_ENCRYPTION_PUBLIC_KEY, _encryptionKeyPair.publicKey.toString());
      logger
          .finer('encryption public key update result $encryptKeyUpdateResult');
      var deleteBuilder = DeleteVerbBuilder()..atKey = AT_CRAM_SECRET;
      var deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
      logger.finer('cram secret delete response : $deleteResponse');
      //mapping encryption keys pairs to their names
      _atKeysMap = {
        AuthKeyType.pkamPublicKey: EncryptionUtil.encryptValue(
            _pkamRsaKeypair.publicKey.toString(), _selfEncryptionKey),
        AuthKeyType.pkamPrivateKey: EncryptionUtil.encryptValue(
            _pkamRsaKeypair.privateKey.toString(), _selfEncryptionKey),
        AuthKeyType.encryptionPublicKey: EncryptionUtil.encryptValue(
            _encryptionKeyPair.publicKey.toString(), _selfEncryptionKey),
        AuthKeyType.encryptionPrivateKey: EncryptionUtil.encryptValue(
            _encryptionKeyPair.privateKey.toString(), _selfEncryptionKey),
        AuthKeyType.selfEncryptionKey: _selfEncryptionKey,
        _atSign: _selfEncryptionKey,
      };
      //mechanism needed to store files when save location is not provided
      //generating .atKeys file at path provided in onboardingConfig
      IOSink atKeysFile =
          File('${atOnboardingConfig.downloadPath}/${_atSign}_key.atKeys')
              .openWrite();
      atKeysFile.write(jsonEncode(_atKeysMap));
    } else {
      logger.finer(
          'could not complete pkam authentication. atKeys file not generated');
    }
  }

  ///method to perform pkam authentication
  Future<bool> authenticate() async {
    atOnboardingConfig.privateKey = atOnboardingConfig.privateKey ?? _getPkamPrivateKey(await _readAuthData(atOnboardingConfig.atKeysFilePath));
    _atClient ??= await createAtClient();
    _isPkamAuthenticated = (await _atLookup?.authenticate(atOnboardingConfig.privateKey))!;
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
          jsonDecodedData[AuthKeyType.pkamPrivateKey],
          _getDecryptionKey(jsonData));
    } else {
      return null;
    }
  }

  ///method to extract decryption key from atKeysData
  String _getDecryptionKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    var key = jsonDecodedData[AuthKeyType.selfEncryptionKey];
    return key;
  }

  AtLookupImpl? getAtLookup() {
    return _atLookup;
  }

  ///generates random RSA keypair
  RSAKeypair generateRsaKeypair() {
    return RSAKeypair.fromRandom();
  }

  ///generate random AES key
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
