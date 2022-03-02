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

///class containing service that can onboard/activate/authenticate @signs
class AtOnboardingServiceImpl implements AtOnboardingService {
  String _atSign;
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
    if (atOnboardingPreference.cramSecret != null) {
      _atLookup = AtLookupImpl(_atSign, atOnboardingPreference.rootDomain,
          atOnboardingPreference.rootPort);
      _isAtsignOnboarded = (await _atLookup
          ?.authenticate_cram(atOnboardingPreference.cramSecret))!;
      if (_isAtsignOnboarded == true) {
        await _activateAtsign();
        logger.finer('cram authentication successful');
        return true;
      }
      return false;
    }
    throw UnAuthenticatedException(
        'either of cram secret or qr code containing cram secret not provided');
  }

  ///method to generate/write/update encryption key-pairs
  Future<void> _activateAtsign() async {
    RSAKeypair _pkamRsaKeypair;
    RSAKeypair _encryptionKeyPair;
    String _selfEncryptionKey;
    Map _atKeysMap;
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
    //updating values to local secondary
    // _persistKeysLocalSecondary(AT_PKAM_PUBLIC_KEY, _pkamRsaKeypair.publicKey.toString());
    // _persistKeysLocalSecondary(AT_PKAM_PRIVATE_KEY, _pkamRsaKeypair.publicKey.toString());
    atOnboardingPreference.privateKey = _pkamRsaKeypair.privateKey.toString();
    //authenticate using pkam to verify insertion of pkamPublicKey
    _isPkamAuthenticated = await authenticate();
    if (_isPkamAuthenticated) {
      _isPkamAuthenticated = true;
      //generate selfEncryptionKey
      _selfEncryptionKey = generateAESKey();
      logger.finer('generating encryption keypair');
      //update self encryption key to local secondary
      // _persistKeysLocalSecondary(AT_ENCRYPTION_SELF_KEY, _selfEncryptionKey);
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
      //update user encryption keys to local secondary
      // _persistKeysLocalSecondary(AT_ENCRYPTION_PUBLIC_KEY, _encryptionKeyPair.publicKey.toString());
      // _persistKeysLocalSecondary(AT_ENCRYPTION_PRIVATE_KEY, _encryptionKeyPair.privateKey.toString());
      //deleting cram secret from the keystore as cram auth is complete
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await _atLookup?.executeVerb(deleteBuilder);
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
      _persistEncryptionKeys(_atKeysMap);
      _persistKeysLocalSecondary(_atKeysMap, false);
      logger.finer(getServerStatus().toString());
    } else {
      logger.finer('could not complete pkam authentication');
    }
  }

  void _persistKeysLocalSecondary(Map? _atKeysMap, bool isPkam) async{
    if(isPkam) {
      _atKeysMap = (await _decryptAtKeysFile(_readAtKeysFile(atOnboardingPreference.atKeysFilePath)));
    }
    if(!isPkam){
      _atKeysMap = await _decryptAtKeysFile(_atKeysMap, decryptionKey: _atKeysMap![AuthKeyType.selfEncryptionKey]);
    }
    if(_atKeysMap != null) {
      bool? response = await _atClient?.getLocalSecondary()?.putValue(
          AuthKeyType.pkamPublicKey, _atKeysMap[AuthKeyType.pkamPublicKey]);
      logger.finer('pkamPublicKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AuthKeyType.pkamPrivateKey, _atKeysMap[AuthKeyType.pkamPrivateKey]);
      logger.finer('pkamPrivateKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AuthKeyType.encryptionPublicKey,
          _atKeysMap[AuthKeyType.encryptionPublicKey]);
      logger.finer('encryptionPublicKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AuthKeyType.encryptionPrivateKey,
          _atKeysMap[AuthKeyType.encryptionPrivateKey]);
      logger.finer('encryptionPrivateKey persist status $response');
      response = await _atClient?.getLocalSecondary()?.putValue(
          AuthKeyType.selfEncryptionKey,
          _atKeysMap[AuthKeyType.selfEncryptionKey]);
      logger.finer('self encryption key persist status $response');
    }
    else{
      logger.severe('atKeysMap is null');
    }
  }

  void _persistEncryptionKeys(Map atKeysMap) {
    //generating .atKeys file at path provided in onboardingConfig
    if(atOnboardingPreference.downloadPath != null) {
      IOSink atKeysFile =
      File('${atOnboardingPreference.downloadPath}/${_atSign}_key.atKeys')
          .openWrite();
      atKeysFile.write(jsonEncode(atKeysMap));
      logger.finer('.atKeys file saved at ${atOnboardingPreference.downloadPath}');
    }
    else {
      throw 'download path not provided';
    }
  }

  @override
  Future<bool> authenticate() async {
    atOnboardingPreference.privateKey = atOnboardingPreference.privateKey ??
        _getPkamPrivateKey(
            await _readAtKeysFile(atOnboardingPreference.atKeysFilePath));
    if (atOnboardingPreference.privateKey != null) {
      _atClient ??= await getAtClient();
      _isPkamAuthenticated =
          (await _atLookup?.authenticate(atOnboardingPreference.privateKey))!;
      return _isPkamAuthenticated;
    }
    throw UnAuthenticatedException(
        'either of private key or .atKeys file not provided');
  }

  ///method to read and return data from .atKeysFile
  Future<String?> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath != null) {
      File atKeysFile = File(atKeysFilePath);
      String atAuthData = await atKeysFile.readAsString();
      return atAuthData;
    } else {
      return null;
    }
  }

  ///method to extract and decrypt pkamPrivateKey from atKeysData
  String? _getPkamPrivateKey(String? jsonData) {
    if (jsonData != null) {
      Map jsonDecodedData = jsonDecode(jsonData);
      String privateKey = EncryptionUtil.decryptValue(
          jsonDecodedData[AuthKeyType.pkamPrivateKey],
          _getDecryptionKey(jsonData));
      return privateKey;
    } else {
      return null;
    }
  }

  ///method to extract decryption key from atKeysData
  String _getDecryptionKey(String jsonData) {
    Map jsonDecodedData = jsonDecode(jsonData);
    return jsonDecodedData[AuthKeyType.selfEncryptionKey];
  }

  Future<Map?> _decryptAtKeysFile(jsonData, {String? decryptionKey}) async {
    //String jsonDecoded = jsonDecode(jsonData);
    decryptionKey ??= await _readAtKeysFile(_getDecryptionKey(jsonData));
    Map _atKeysMap = {
      AuthKeyType.pkamPublicKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPublicKey], decryptionKey!),
      AuthKeyType.pkamPrivateKey: EncryptionUtil.decryptValue(
          jsonData[AuthKeyType.pkamPrivateKey], decryptionKey),
      AuthKeyType.encryptionPublicKey: EncryptionUtil.decryptValue(
          AuthKeyType.encryptionPublicKey, decryptionKey),
      AuthKeyType.encryptionPrivateKey: EncryptionUtil.decryptValue(
          AuthKeyType.encryptionPublicKey, decryptionKey),
      AuthKeyType.selfEncryptionKey: decryptionKey,
    };
  }

  ///generates random RSA keypair
  RSAKeypair generateRsaKeypair() {
    return RSAKeypair.fromRandom();
  }

  ///generate random AES key
  String generateAESKey() {
    var aesKey = AES(Key.fromSecureRandom(32));
    return aesKey.key.base64;
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
