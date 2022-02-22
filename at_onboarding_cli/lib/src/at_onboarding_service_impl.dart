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

///class containing service that can onboard/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  String _atSign;
  bool _isPkamAuthenticated = false;
  bool _isAtsignOnboarded = false;
  AtLookupImpl? _atLookup;
  AtClient? _atClient;
  AtSignLogger logger = AtSignLogger('Onboarding CLI');
  AtOnboardingPreference atOnboardingPreference;

  AtClient? get atClient => _atClient;
  AtLookupImpl? get atLookup => _atLookup;

  AtOnboardingServiceImpl(this._atSign, this.atOnboardingPreference);

  ///creates and returns instance of [AtClient] using [AtOnboardingPreference]
  Future<AtClient?> getAtClient() async {
    if (_atClient == null) {
      AtClientManager _atClientManager = AtClientManager.getInstance();
      await _atClientManager.setCurrentAtSign(
          _atSign, atOnboardingPreference.namespace, atOnboardingPreference);
      var atClient = _atClientManager.atClient;
      _atLookup = atClient.getRemoteSecondary()?.atLookUp;
      return atClient;
    }
  }

  @override
  Future<bool> onboard() async {
    //get cram_secret from either from AtOnboardingConfig or decode it from qr code whichever available
    var secret = atOnboardingPreference.cramSecret ??
        _getSecretFromQr(atOnboardingPreference.qrCodePath);
    _atLookup = AtLookupImpl(_atSign, atOnboardingPreference.rootDomain,
        atOnboardingPreference.rootPort);
    _isAtsignOnboarded = (await _atLookup?.authenticate_cram(secret))!;
    logger.severe('cram status $_isAtsignOnboarded');
    if (_isAtsignOnboarded == true) {
      await _generateEncryptionKeyPairs();
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
    var updateCommand =
        'update:$AT_PKAM_PUBLIC_KEY ${_pkamRsaKeypair.publicKey}\n';
    //updating pkamPublicKey to remote secondary
    var pkamUpdateResult =
        await _atLookup?.executeCommand(updateCommand, auth: false);
    logger.finer('pkam update result: $pkamUpdateResult');
    atOnboardingPreference.privateKey = _pkamRsaKeypair.privateKey.toString();
    var pubK = await _atLookup?.llookup(AT_PKAM_PUBLIC_KEY);
    pubK = pubK?.split(':')[1];
    _isPkamAuthenticated = await authenticate();
    if (_isPkamAuthenticated) {
      _isPkamAuthenticated = true;
      //generate selfEncryptionKey
      _selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
      //generate user encryption keypair
      _encryptionKeyPair = generateRsaKeypair();
      var updateCommand =
          'update:$AT_ENCRYPTION_PUBLIC_KEY@$_atSign ${_encryptionKeyPair.publicKey}\n';
      //update user encryption public key
      var encryptKeyUpdateResult =
          await _atLookup?.executeCommand(updateCommand);
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
          File('${atOnboardingPreference.downloadPath}/${_atSign}_key.atKeys')
              .openWrite();
      atKeysFile.write(jsonEncode(_atKeysMap));
    } else {
      logger.finer(
          'could not complete pkam authentication. atKeys file not generated');
    }
  }

  @override
  Future<bool> authenticate() async {
    atOnboardingPreference.privateKey = atOnboardingPreference.privateKey ??
        _getPkamPrivateKey(
            await _readAuthData(atOnboardingPreference.atKeysFilePath));
    _atClient ??= await getAtClient();
    _isPkamAuthenticated =
        (await _atLookup?.authenticate(atOnboardingPreference.privateKey))!;
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

  Future<AtStatus> getServerStatus() {
    AtServerStatus atServerStatus = AtStatusImpl(
        rootUrl: atOnboardingPreference.rootDomain,
        rootPort: atOnboardingPreference.rootPort);
    return atServerStatus.get(_atSign);
  }

  ///extracts cram secret from qrCode
  dynamic _getSecretFromQr(String? path) {
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
