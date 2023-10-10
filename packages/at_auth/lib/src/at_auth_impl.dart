import 'dart:convert';
import 'dart:io';

import 'package:at_auth/src/at_auth_base.dart';
import 'package:at_auth/src/auth/cram_authenticator.dart';
import 'package:at_auth/src/keys/at_security_keys.dart';
import 'package:at_auth/src/onboard/at_onboarding_request.dart';
import 'package:at_auth/src/onboard/at_onboarding_response.dart';
import 'package:at_auth/src/onboarding_exceptions.dart';
import 'package:at_auth/src/auth/at_auth_request.dart';
import 'package:at_auth/src/auth/at_auth_response.dart';
import 'package:at_auth/src/auth_constants.dart' as auth_constants;
import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/at_chops_base.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_logger.dart';

class AtAuthImpl implements AtAuth {
  final AtSignLogger _logger = AtSignLogger('AtAuthServiceImpl');
  @override
  AtChops? atChops;

  CramAuthenticator? _cramAuthenticator;

  AtLookUp? _atLookUp;

  @override
  Future<AtAuthResponse> authenticate(AtAuthRequest atAuthRequest) async {
    if (atAuthRequest.atKeysFilePath == null &&
        atAuthRequest.atSecurityKeys == null) {
      throw UnAuthenticatedException(
          'Keyfile path or atSecurityKeys object has to be set in atAuthRequest');
    }
    // decrypts all the keys in .atKeysFile using the SelfEncryptionKey
    // and stores the keys in a map
    var atSecurityKeys;
    if (atAuthRequest.atKeysFilePath != null) {
      atSecurityKeys = _decryptAtKeysFile(
          await _readAtKeysFile(atAuthRequest.atKeysFilePath),
          atAuthRequest.authMode);
    } else {
      atSecurityKeys = atAuthRequest.atSecurityKeys;
    }
    var pkamPrivateKey = atSecurityKeys.apkamPrivateKey;

    if (atAuthRequest.authMode == PkamAuthMode.keysFile &&
        pkamPrivateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Unable to read PkamPrivateKey from provided atKeys file at path: '
          '${atAuthRequest.atKeysFilePath}. Please provide a valid atKeys file',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    var atChops = _createAtChops(atSecurityKeys);
    this.atChops = atChops;
    _atLookUp!.atChops = atChops;
    _logger.finer('Authenticating using PKAM');
    var isPkamAuthenticated = false;
    try {
      isPkamAuthenticated =
          (await _atLookUp?.pkamAuthenticate(enrollmentId: enrollmentId))!;
    } on Exception catch (e) {
      _logger.severe('Caught exception: $e');
      throw UnAuthenticatedException('Unable to authenticate- ${e.toString()}');
    }
    _logger.finer(
        'PKAM auth result: ${isPkamAuthenticated ? 'success' : 'failed'}');
    return AtAuthResponse(atAuthRequest.atSign)
      ..isSuccessful = isPkamAuthenticated;
  }

  @override
  Future<bool> isOnboarded({String? atSign}) {
    // TODO: implement isOnboarded
    throw UnimplementedError();
  }

  @override
  Future<AtOnboardingResponse> onboard(
      AtOnboardingRequest atOnboardingRequest, String cramSecret) async {
    var atOnboardingResponse = AtOnboardingResponse(atOnboardingRequest.atSign);
    _atLookUp = AtLookupImpl(atOnboardingRequest.atSign,
        atOnboardingRequest.rootDomain, atOnboardingRequest.rootPort);

    //1. cram auth
    _cramAuthenticator ??=
        CramAuthenticator(atOnboardingRequest.atSign, cramSecret, _atLookUp);
    var cramAuthResult = await _cramAuthenticator!.authenticate();
    if (!cramAuthResult.isSuccessful) {
      throw AtOnboardingException(
          'Cram authentication failed. Please check the cram key'
          ' and try again \n(or) contact support@atsign.com');
    }
    //2. generate key pairs
    var atSecurityKeys = _generateKeyPairs(atOnboardingRequest.authMode,
        publicKeyId: atOnboardingRequest.publicKeyId);

    var atChops = _createAtChops(atSecurityKeys);
    this.atChops = atChops;
    _atLookUp!.atChops = atChops;

    //3. update pkam public key through enrollment or manually based on app preference
    String? enrollmentIdFromServer;
    if (atOnboardingRequest.enableEnrollment) {
      // server will update the apkam public key during enrollment.So don't have to manually update in this scenario.
      enrollmentIdFromServer = await _sendOnboardingEnrollment(
          atOnboardingRequest, atSecurityKeys, _atLookUp!);
      atSecurityKeys.enrollmentId = enrollmentIdFromServer;
    } else {
      // update pkam public key to server if enrollment is not set in preference
      _logger.finer('Updating PkamPublicKey to remote secondary');
      final pkamPublicKey = atSecurityKeys.apkamPublicKey;
      String updateCommand = 'update:$AT_PKAM_PUBLIC_KEY $pkamPublicKey\n';
      String? pkamUpdateResult =
          await _atLookUp!.executeCommand(updateCommand, auth: false);
      _logger.info('PkamPublicKey update result: $pkamUpdateResult');
    }

    //3. Close connection to server
    try {
      (_atLookUp as AtLookupImpl).close();
    } on Exception catch (e) {
      _logger.severe('error while closing connection to server: $e');
    }

    //4. Init _atLookUp again and attempt pkam auth
    _atLookUp = AtLookupImpl(atOnboardingRequest.atSign,
        atOnboardingRequest.rootDomain, atOnboardingRequest.rootPort);
    _atLookUp!.atChops = atChops;

    var isPkamAuthenticated = false;
    //5. Do pkam auth
    try {
      isPkamAuthenticated = await _atLookUp!
          .pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
    } on UnAuthenticatedException catch (e) {
      throw AtOnboardingException('Pkam auth failed - $e ');
    }
    if (!isPkamAuthenticated) {
      throw AtOnboardingException('Pkam auth returned false');
    }

    //5. If Pkam auth is success, update encryption public key to secondary and delete cram key from server
    final encryptionPublicKey = atSecurityKeys.defaultEncryptionPublicKey;
    UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
      ..atKey = 'publickey'
      ..isPublic = true
      ..value = encryptionPublicKey
      ..sharedBy = atOnboardingRequest.atSign;
    String? encryptKeyUpdateResult =
        await _atLookUp!.executeVerb(updateBuilder);
    _logger.info('Encryption public key update result $encryptKeyUpdateResult');
    // deleting cram secret from the keystore as cram auth is complete
    DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
      ..atKey = AT_CRAM_SECRET;
    String? deleteResponse = await _atLookUp!.executeVerb(deleteBuilder);
    _logger.info('Cram secret delete response : $deleteResponse');

    return atOnboardingResponse;
  }

  AtChops _createAtChops(AtSecurityKeys atKeysFile) {
    final atEncryptionKeyPair = AtEncryptionKeyPair.create(
        atKeysFile.defaultEncryptionPublicKey!,
        atKeysFile.defaultEncryptionPrivateKey!);
    final atPkamKeyPair = AtPkamKeyPair.create(
        atKeysFile.apkamPublicKey!, atKeysFile.apkamPrivateKey!);
    final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
    if (atKeysFile.apkamSymmetricKey != null) {
      atChopsKeys.apkamSymmetricKey = AESKey(atKeysFile.apkamSymmetricKey!);
    }
    atChopsKeys.selfEncryptionKey =
        AESKey(atKeysFile.defaultSelfEncryptionKey!);
    return AtChopsImpl(atChopsKeys);
  }

  Future<String> _sendOnboardingEnrollment(
      AtOnboardingRequest atOnboardingRequest,
      AtSecurityKeys atSecurityKeys,
      AtLookUp atLookup) async {
    var enrollBuilder = EnrollVerbBuilder()
      ..appName = atOnboardingRequest.appName
      ..deviceName = atOnboardingRequest.deviceName;

    var symmetricEncryptionAlgo =
        AESEncryptionAlgo(AESKey(atSecurityKeys.apkamSymmetricKey!));
    enrollBuilder.encryptedDefaultEncryptedPrivateKey = atChops!
        .encryptString(atSecurityKeys.defaultEncryptionPrivateKey!,
            EncryptionKeyType.aes256,
            encryptionAlgorithm: symmetricEncryptionAlgo,
            iv: AtChopsUtil.generateIVLegacy())
        .result;

    enrollBuilder.encryptedDefaultSelfEncryptionKey = atChops!
        .encryptString(
            atSecurityKeys.defaultSelfEncryptionKey!, EncryptionKeyType.aes256,
            encryptionAlgorithm: symmetricEncryptionAlgo,
            iv: AtChopsUtil.generateIVLegacy())
        .result;
    enrollBuilder.apkamPublicKey = atSecurityKeys.apkamPublicKey;

    var enrollResult = await atLookup
        .executeCommand(enrollBuilder.buildCommand(), auth: false);
    if (enrollResult == null || enrollResult.isEmpty) {
      throw AtOnboardingException('Enrollment response is null or empty');
    } else if (enrollResult.startsWith('error:')) {
      throw AtOnboardingException('Enrollment error:$enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    _logger.finer('enrollResult: $enrollResult');
    var enrollResultJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollResultJson[enrollmentId];
    var enrollmentStatus = enrollResultJson['status'];
    if (enrollmentStatus != 'approved') {
      throw AtOnboardingException(
          'initial enrollment is not approved. Status from server: $enrollmentStatus');
    }
    return enrollmentIdFromServer;
  }

  AtSecurityKeys _decryptAtKeysFile(
      Map<String, String> jsonData, PkamAuthMode authMode) {
    var securityKeys = AtSecurityKeys();
    String decryptionKey = jsonData[auth_constants.defaultSelfEncryptionKey]!;
    var atChops =
        AtChopsImpl(AtChopsKeys()..selfEncryptionKey = AESKey(decryptionKey));
    securityKeys.defaultEncryptionPublicKey = atChops
        .decryptString(jsonData[auth_constants.defaultEncryptionPublicKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey')
        .result;
    securityKeys.defaultEncryptionPrivateKey = atChops
        .decryptString(jsonData[auth_constants.defaultEncryptionPrivateKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey')
        .result;
    securityKeys.defaultSelfEncryptionKey = decryptionKey;
    securityKeys.apkamPublicKey = atChops
        .decryptString(
            jsonData[auth_constants.apkamPublicKey]!, EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey')
        .result;
    // pkam private key will not be saved in keyfile if auth mode is sim/any other secure element.
    // decrypt the private key only when auth mode is keysFile
    if (authMode == PkamAuthMode.keysFile) {
      securityKeys.apkamPrivateKey = atChops
          .decryptString(jsonData[auth_constants.apkamPrivateKey]!,
              EncryptionKeyType.aes256,
              keyName: 'selfEncryptionKey')
          .result;
    }
    securityKeys.apkamSymmetricKey = jsonData[auth_constants.apkamSymmetricKey];
    securityKeys.enrollmentId = jsonData[enrollmentId];
    return securityKeys;
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map<String, String>> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath == null || atKeysFilePath.isEmpty) {
      throw AtException(
          'atKeys filePath is empty. atKeysFile is required to authenticate');
    }
    String atAuthData = await File(atKeysFilePath).readAsString();
    Map<String, String> jsonData = <String, String>{};
    json.decode(atAuthData).forEach((String key, dynamic value) {
      jsonData[key] = value.toString();
    });
    return jsonData;
  }

  AtSecurityKeys _generateKeyPairs(PkamAuthMode authMode,
      {String? publicKeyId}) {
    // generate user encryption keypair
    _logger.info('Generating encryption keypair');
    var atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();

    //generate selfEncryptionKey
    var selfEncryptionKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    var apkamSymmetricKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    var atKeysFile = AtSecurityKeys();
    _logger.info(
        '[Information] Generating your encryption keys and .atKeys file\n');
    //generating pkamKeyPair only if authMode is keysFile
    var pkamPublicKey;
    if (authMode == PkamAuthMode.keysFile) {
      _logger.info('Generating pkam keypair');
      var apkamRsaKeypair = AtChopsUtil.generateAtPkamKeyPair();
      pkamPublicKey = apkamRsaKeypair.atPublicKey.publicKey.toString();
      atKeysFile.apkamPrivateKey =
          apkamRsaKeypair.atPrivateKey.privateKey.toString();
    } else if (authMode == PkamAuthMode.sim) {
      // get the public key from secure element
      pkamPublicKey = atChops!.readPublicKey(publicKeyId!);
      _logger.info('pkam  public key from sim: ${atKeysFile.apkamPublicKey}');

      // encryption key pair and self encryption symmetric key
      // are not available to injected at_chops. Set it here
      atChops!.atChopsKeys.atEncryptionKeyPair = atEncryptionKeyPair;
      atChops!.atChopsKeys.selfEncryptionKey = selfEncryptionKey;
      atChops!.atChopsKeys.apkamSymmetricKey = apkamSymmetricKey;
    }
    atKeysFile.apkamPublicKey = pkamPublicKey;
    //Standard order of an atKeys file is ->
    // pkam keypair -> encryption keypair -> selfEncryption key -> enrollmentId --> apkam symmetric key -->
    // @sign: selfEncryptionKey[self encryption key again]
    // note: "->" stands for "followed by"
    atKeysFile.defaultEncryptionPublicKey =
        atEncryptionKeyPair.atPublicKey.publicKey.toString();
    atKeysFile.defaultEncryptionPrivateKey =
        atEncryptionKeyPair.atPrivateKey.privateKey.toString();
    atKeysFile.defaultSelfEncryptionKey = selfEncryptionKey.key;
    atKeysFile.apkamSymmetricKey = apkamSymmetricKey.key;

    return atKeysFile;
  }
}
