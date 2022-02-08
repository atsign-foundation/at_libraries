import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';

class OnboardingService {
  late final String _rootDomain;
  late final int _rootPort;
  late String _atSign;
  bool _isPkamAuthenticated = false;
  late final AtLookupImpl _atLookup =
      AtLookupImpl(_atSign, _rootDomain, _rootPort);
  AtSignLogger logger = AtSignLogger('Onboarding CLI');
  AtOnboardingConfig atOnboardingConfig = AtOnboardingConfig();

  OnboardingService(this._atSign) {
    _rootDomain = atOnboardingConfig.getRootServerDomain();
    _rootPort = atOnboardingConfig.getRootServerPort();
  }

  Future<bool> onboard() async {
    var qrPath = atOnboardingConfig.getQrCodePath();
    var qrData = atOnboardingConfig.getQrData(qrPath!);
    String secret = qrData.text;
    secret = secret.split(":")[1];
    logger.severe(secret);
    var isCramSuccessful = await _atLookup.authenticate_cram(secret);
    if (isCramSuccessful) {
      generateEncryptionKeyPairs();
    }
    return isCramSuccessful;
  }

  Future<void> generateEncryptionKeyPairs() async {
    RSAKeypair pkamRsaKeypair;
    RSAKeypair encryptionKeyPair;
    var selfEncryptionKey;
    logger.finer('generating pkam keypair');
    pkamRsaKeypair = generateRsaKeypair();
    logger.finer('updating pkam public key to remote secondary');
    var updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${pkamRsaKeypair.publicKey}';
    var pkamUpdateResult = _atLookup.executeCommand(updateCommand);
    logger.finer('pkam update result: $pkamUpdateResult');

    var pkamAuth =
        await _atLookup.authenticate(pkamRsaKeypair.privateKey.toString());

    if (pkamAuth) {
      _isPkamAuthenticated = true;
      selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
      encryptionKeyPair = generateRsaKeypair();
      updateCommand =
          'update:$AT_ENCRYPTION_PUBLIC_KEY ${encryptionKeyPair.publicKey}';
      var encryptKeyUpdateResult =
          await _atLookup.executeCommand(updateCommand);
      logger
          .finer('encryption public key udpate result $encryptKeyUpdateResult');
      var deleteBuilder = DeleteVerbBuilder()..atKey = AT_CRAM_SECRET;
      var deleteResponse = await _atLookup.executeVerb(deleteBuilder);
      logger.finer('cram secret delete response : $deleteResponse');
    }

    Map _atKeysData() => {
          "aesPkamPublicKey": EncryptionUtil.encryptValue(
              pkamRsaKeypair.publicKey.toString(), selfEncryptionKey),
          "aesPkamPrivateKey": EncryptionUtil.encryptValue(
              pkamRsaKeypair.privateKey.toString(), selfEncryptionKey),
          "aes-EncryptPublicKey": EncryptionUtil.encryptValue(
              encryptionKeyPair.publicKey.toString(), selfEncryptionKey),
          "aesEncryptPrivateKey": EncryptionUtil.encryptValue(
              encryptionKeyPair.privateKey.toString(), selfEncryptionKey),
          "selfEncryptionKey": selfEncryptionKey,
          _atSign: selfEncryptionKey,
        };

    IOSink atKeysFile = File('/home/srie/Documents/genFile.atKeys').openWrite();
    atKeysFile.write(jsonEncode(_atKeysData));
  }

  Future<String> _readAuthData(String atKeysFilePath) async {
    File atKeysFile = File(atKeysFilePath);
    String atAuthData = await atKeysFile.readAsString();
    return atAuthData;
  }

  String _getPkamPrivateKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    return EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PRIVATE_KEY_FROM_KEY_FILE],
        _getDecryptionKey(jsonData));
  }

  String _getDecryptionKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    var key = jsonDecodedData[AuthKeyType.SELF_ENCRYPTION_KEY_FROM_FILE];
    return key;
  }

  Future<bool> authenticate() async {
    String? filePath = atOnboardingConfig.getAtKeysFilePath();
    if (filePath != null) {
      String atAuthData = await _readAuthData(filePath);
      _isPkamAuthenticated =
          await _atLookup.authenticate(_getPkamPrivateKey(atAuthData));
      print(_isPkamAuthenticated);
    } else if (filePath == null) {
      logger.severe('AtKeysFile path is null');
    }
    return _isPkamAuthenticated;
  }

  AtLookupImpl getAtLookup() {
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
}
