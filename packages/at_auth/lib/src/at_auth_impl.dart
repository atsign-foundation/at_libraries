import 'dart:convert';
import 'dart:io';

import 'package:at_auth/src/at_auth_base.dart';
import 'package:at_auth/src/auth/cram_authenticator.dart';
import 'package:at_auth/src/auth/pkam_authenticator.dart';
import 'package:at_auth/src/keys/at_auth_keys.dart';
import 'package:at_auth/src/onboard/at_onboarding_request.dart';
import 'package:at_auth/src/onboard/at_onboarding_response.dart';
import 'package:at_auth/src/exception/at_auth_exceptions.dart';
import 'package:at_auth/src/auth/at_auth_request.dart';
import 'package:at_auth/src/auth/at_auth_response.dart';
import 'package:at_auth/src/auth_constants.dart' as auth_constants;
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_logger.dart';

class AtAuthImpl implements AtAuth {
  final AtSignLogger _logger = AtSignLogger('AtAuthServiceImpl');
  @override
  AtChops? atChops;

  CramAuthenticator? cramAuthenticator;

  PkamAuthenticator? pkamAuthenticator;

  AtLookUp? atLookUp;

  AtAuthImpl(
      {this.atLookUp,
      this.atChops,
      this.cramAuthenticator,
      this.pkamAuthenticator});

  @override
  Future<AtAuthResponse> authenticate(AtAuthRequest atAuthRequest) async {
    if (atAuthRequest.atKeysFilePath == null &&
        atAuthRequest.atAuthKeys == null &&
        atAuthRequest.encryptedKeysMap == null) {
      throw AtAuthenticationException(
          'Keyfile path or atAuthKeys object has to be set in atAuthRequest');
    }
    // decrypts all the keys in .atKeysFile using the SelfEncryptionKey
    // and stores the keys in a map
    AtAuthKeys? atAuthKeys;
    var enrollmentIdFromRequest = atAuthRequest.enrollmentId;
    if (atAuthRequest.atKeysFilePath != null) {
      atAuthKeys = _decryptAtKeysFile(
          await _readAtKeysFile(atAuthRequest.atKeysFilePath),
          atAuthRequest.authMode);
    } else if (atAuthRequest.encryptedKeysMap != null) {
      atAuthKeys = _decryptAtKeysFile(
          atAuthRequest.encryptedKeysMap!, PkamAuthMode.keysFile);
    } else {
      atAuthKeys = atAuthRequest.atAuthKeys;
    }
    if (atAuthKeys == null) {
      throw AtAuthenticationException(
          'keys either were not provided in the AtAuthRequest, or could not be read from provided keys file');
    }
    enrollmentIdFromRequest ??= atAuthKeys.enrollmentId;
    var pkamPrivateKey = atAuthKeys.apkamPrivateKey;

    if (atAuthRequest.authMode == PkamAuthMode.keysFile &&
        pkamPrivateKey == null) {
      throw AtPrivateKeyNotFoundException(
          'Unable to read PkamPrivateKey from provided atKeys file/atAuthKeys object',
          exceptionScenario: ExceptionScenario.invalidValueProvided);
    }
    atLookUp ??= AtLookupImpl(
        atAuthRequest.atSign, atAuthRequest.rootDomain, atAuthRequest.rootPort);
    var atChops = _createAtChops(atAuthKeys);
    this.atChops = atChops;
    atLookUp!.atChops = atChops;
    _logger.finer('Authenticating using PKAM');
    var isPkamAuthenticated = false;
    pkamAuthenticator ??= PkamAuthenticator(atAuthRequest.atSign, atLookUp!);
    try {
      var pkamResponse = (await pkamAuthenticator!
          .authenticate(enrollmentId: enrollmentIdFromRequest));
      isPkamAuthenticated = pkamResponse.isSuccessful;
    } on Exception catch (e) {
      _logger.severe('Caught exception: $e');
      throw AtAuthenticationException(
          'Unable to authenticate- ${e.toString()}');
    }
    _logger.finer(
        'PKAM auth result: ${isPkamAuthenticated ? 'success' : 'failed'}');
    return AtAuthResponse(atAuthRequest.atSign)
      ..isSuccessful = isPkamAuthenticated
      ..enrollmentId = enrollmentIdFromRequest
      ..atAuthKeys = atAuthKeys;
  }

  @override
  Future<AtOnboardingResponse> onboard(
      AtOnboardingRequest atOnboardingRequest, String cramSecret) async {
    var atOnboardingResponse = AtOnboardingResponse(atOnboardingRequest.atSign);
    atLookUp ??= AtLookupImpl(atOnboardingRequest.atSign,
        atOnboardingRequest.rootDomain, atOnboardingRequest.rootPort);

    //1. cram auth
    cramAuthenticator ??=
        CramAuthenticator(atOnboardingRequest.atSign, cramSecret, atLookUp);
    var cramAuthResult = await cramAuthenticator!.authenticate();
    if (!cramAuthResult.isSuccessful) {
      throw AtAuthenticationException(
          'Cram authentication failed. Please check the cram key'
          ' and try again \n(or) contact support@atsign.com');
    }
    //2. generate key pairs
    var atAuthKeys = _generateKeyPairs(atOnboardingRequest.authMode,
        publicKeyId: atOnboardingRequest.publicKeyId);
    if (atChops == null) {
      var atChops = _createAtChops(atAuthKeys);
      this.atChops = atChops;
      atLookUp!.atChops = atChops;
    }

    //3. update pkam public key through enrollment or manually based on app preference
    String? enrollmentIdFromServer;
    if (atOnboardingRequest.enableEnrollment) {
      // server will update the apkam public key during enrollment.So don't have to manually update in this scenario.
      enrollmentIdFromServer = await _sendOnboardingEnrollment(
          atOnboardingRequest, atAuthKeys, atLookUp!);
      atAuthKeys.enrollmentId = enrollmentIdFromServer;
    } else {
      // update pkam public key to server if enrollment is not set in preference
      _logger.finer('Updating PkamPublicKey to remote secondary');
      final pkamPublicKey = atAuthKeys.apkamPublicKey;
      String updateCommand =
          'update:${AtConstants.atPkamPublicKey} $pkamPublicKey\n';
      String? pkamUpdateResult =
          await atLookUp!.executeCommand(updateCommand, auth: false);
      _logger.finer('PkamPublicKey update result: $pkamUpdateResult');
    }

    //3. Close connection to server
    try {
      await (atLookUp as AtLookupImpl).close();
    } on Exception catch (e) {
      _logger.severe('error while closing connection to server: $e');
    }

    //4. Init _atLookUp again and attempt pkam auth
    // atLookUp = AtLookupImpl(atOnboardingRequest.atSign,
    //     atOnboardingRequest.rootDomain, atOnboardingRequest.rootPort);
    atLookUp!.atChops = atChops;

    var isPkamAuthenticated = false;
    //5. Do pkam auth
    pkamAuthenticator ??=
        PkamAuthenticator(atOnboardingRequest.atSign, atLookUp!);
    try {
      var pkamResponse = await pkamAuthenticator!
          .authenticate(enrollmentId: enrollmentIdFromServer);
      isPkamAuthenticated = pkamResponse.isSuccessful;
    } on UnAuthenticatedException catch (e) {
      throw AtAuthenticationException('Pkam auth failed - $e ');
    }
    if (!isPkamAuthenticated) {
      throw AtAuthenticationException('Pkam auth returned false');
    }

    //5. If Pkam auth is success, update encryption public key to secondary and delete cram key from server
    final encryptionPublicKey = atAuthKeys.defaultEncryptionPublicKey;
    UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
      ..atKey = 'publickey'
      ..isPublic = true
      ..value = encryptionPublicKey
      ..sharedBy = atOnboardingRequest.atSign;
    String? encryptKeyUpdateResult = await atLookUp!.executeVerb(updateBuilder);
    _logger.info('Encryption public key update result $encryptKeyUpdateResult');
    // deleting cram secret from the keystore as cram auth is complete
    DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
      ..atKey = AtConstants.atCramSecret;
    String? deleteResponse = await atLookUp!.executeVerb(deleteBuilder);
    _logger.info('Cram secret delete response : $deleteResponse');
    atOnboardingResponse.isSuccessful = true;
    atOnboardingResponse.enrollmentId = enrollmentIdFromServer;
    atOnboardingResponse.atAuthKeys = atAuthKeys;
    return atOnboardingResponse;
  }

  AtChops _createAtChops(AtAuthKeys atKeysFile) {
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
      AtAuthKeys atAuthKeys,
      AtLookUp atLookup) async {
    var enrollBuilder = EnrollVerbBuilder()
      ..appName = atOnboardingRequest.appName
      ..deviceName = atOnboardingRequest.deviceName;

    var symmetricEncryptionAlgo =
        AESEncryptionAlgo(AESKey(atAuthKeys.apkamSymmetricKey!));
    enrollBuilder.encryptedDefaultEncryptedPrivateKey = atChops!
        .encryptString(
            atAuthKeys.defaultEncryptionPrivateKey!, EncryptionKeyType.aes256,
            encryptionAlgorithm: symmetricEncryptionAlgo,
            iv: AtChopsUtil.generateIVLegacy())
        .result;

    enrollBuilder.encryptedDefaultSelfEncryptionKey = atChops!
        .encryptString(
            atAuthKeys.defaultSelfEncryptionKey!, EncryptionKeyType.aes256,
            encryptionAlgorithm: symmetricEncryptionAlgo,
            iv: AtChopsUtil.generateIVLegacy())
        .result;
    enrollBuilder.apkamPublicKey = atAuthKeys.apkamPublicKey;

    var enrollResult = await atLookup
        .executeCommand(enrollBuilder.buildCommand(), auth: false);
    if (enrollResult == null || enrollResult.isEmpty) {
      throw AtAuthenticationException('Enrollment response is null or empty');
    } else if (enrollResult.startsWith('error:')) {
      throw AtAuthenticationException('Enrollment error:$enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    _logger.finer('enrollResult: $enrollResult');
    var enrollResultJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollResultJson[AtConstants.enrollmentId];
    var enrollmentStatus = enrollResultJson['status'];
    if (enrollmentStatus != 'approved') {
      throw AtAuthenticationException(
          'initial enrollment is not approved. Status from server: $enrollmentStatus');
    }
    return enrollmentIdFromServer;
  }

  AtAuthKeys _decryptAtKeysFile(
      Map<String, dynamic> jsonData, PkamAuthMode authMode) {
    var securityKeys = AtAuthKeys();
    String decryptionKey = jsonData[auth_constants.defaultSelfEncryptionKey]!;
    var atChops =
        AtChopsImpl(AtChopsKeys()..selfEncryptionKey = AESKey(decryptionKey));
    securityKeys.defaultEncryptionPublicKey = atChops
        .decryptString(jsonData[auth_constants.defaultEncryptionPublicKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
        .result;
    securityKeys.defaultEncryptionPrivateKey = atChops
        .decryptString(jsonData[auth_constants.defaultEncryptionPrivateKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
        .result;
    securityKeys.defaultSelfEncryptionKey = decryptionKey;
    securityKeys.apkamPublicKey = atChops
        .decryptString(
            jsonData[auth_constants.apkamPublicKey]!, EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
        .result;
    // pkam private key will not be saved in keyfile if auth mode is sim/any other secure element.
    // decrypt the private key only when auth mode is keysFile
    if (authMode == PkamAuthMode.keysFile) {
      securityKeys.apkamPrivateKey = atChops
          .decryptString(jsonData[auth_constants.apkamPrivateKey]!,
              EncryptionKeyType.aes256,
              keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
          .result;
    }
    securityKeys.apkamSymmetricKey = jsonData[auth_constants.apkamSymmetricKey];
    securityKeys.enrollmentId = jsonData[AtConstants.enrollmentId];
    return securityKeys;
  }

  ///method to read and return data from .atKeysFile
  ///returns map containing encryption keys
  Future<Map<String, String>> _readAtKeysFile(String? atKeysFilePath) async {
    if (atKeysFilePath == null || atKeysFilePath.isEmpty) {
      throw AtException(
          'atKeys filePath is empty. atKeysFile is required to authenticate');
    }
    if (!File(atKeysFilePath).existsSync()) {
      throw AtException(
          'provided keys file does not exist. Please check whether the file path $atKeysFilePath is valid');
    }
    String atAuthData = await File(atKeysFilePath).readAsString();
    Map<String, String> jsonData = <String, String>{};
    json.decode(atAuthData).forEach((String key, dynamic value) {
      jsonData[key] = value.toString();
    });
    return jsonData;
  }

  AtAuthKeys _generateKeyPairs(PkamAuthMode authMode, {String? publicKeyId}) {
    // generate user encryption keypair
    _logger.info('Generating encryption keypair');
    var atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();

    //generate selfEncryptionKey
    var selfEncryptionKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    var apkamSymmetricKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    var atKeysFile = AtAuthKeys();
    _logger.info(
        '[Information] Generating your encryption keys and .atKeys file\n');
    //generating pkamKeyPair only if authMode is keysFile
    String? pkamPublicKey;
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
