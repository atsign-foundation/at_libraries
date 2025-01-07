import 'dart:convert';
import 'dart:io';

import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/auth_constants.dart' as auth_constants;
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_commons.dart';

/// Utility class for handling authentication-related operations
class AtAuthUtils {
  /// Decrypts authentication keys from the specified `.atKeysFile`.
  ///
  /// This method reads the authentication keys file, checks if it is
  /// encrypted with a passphrase, and performs decryption if necessary.
  ///
  /// Throws an [AtException] if the file path is invalid or the file
  /// does not exist. If the file is encrypted, a passphrase is required
  /// to proceed with decryption.
  ///
  /// Returns a map of decryption keys.
  ///
  /// [atAuthRequest] The authentication request containing the keys file
  /// path and passphrase (if any).
  static Future<AtAuthKeys> decryptAtKeys(AtAuthRequest atAuthRequest) {
    return _decryptAtKeysFromFilePath(atAuthRequest);
  }

  static Future<AtAuthKeys> _decryptAtKeysFromFilePath(
      AtAuthRequest atAuthRequest) async {
    if (atAuthRequest.atKeysFilePath == null ||
        atAuthRequest.atKeysFilePath!.isEmpty) {
      throw AtException(
          'atKeys filePath is empty. atKeysFile is required to authenticate');
    }
    if (!File(atAuthRequest.atKeysFilePath!).existsSync()) {
      throw AtException(
          'provided keys file does not exist. Please check whether the file path ${atAuthRequest.atKeysFilePath} is valid');
    }

    String atAuthData =
        await File(atAuthRequest.atKeysFilePath!).readAsString();
    Map<String, dynamic> decodedAtKeysData = jsonDecode(atAuthData);
    // If it contains "iv(InitializationVector)", it means the data is encrypted with a
    // passphrase. Decrypt it.
    if (decodedAtKeysData.containsKey('iv') &&
        atAuthRequest.passPhrase.isNullOrEmpty) {
      throw AtDecryptionException(
          'Pass Phrase is required for password protected atKeys file');
    }
    if (decodedAtKeysData.containsKey('iv')) {
      // _logger.info(
      //     'Found encrypted atKeys files. Decrypting with the given pass-phrase');
      AtEncrypted atEncrypted = AtEncrypted.fromJson(decodedAtKeysData);

      if (atEncrypted.hashingAlgoType == null) {
        throw AtDecryptionException(
            'Hashing algo type is required for decryption of password protected atKeys file');
      }

      String decryptedAtKeys =
          await AtKeysCrypto.fromHashingAlgorithm(atEncrypted.hashingAlgoType!)
              .decrypt(atEncrypted, atAuthRequest.passPhrase!);
      decodedAtKeysData = jsonDecode(decryptedAtKeys);
    }
    // This is to decrypt the atKeys encrypted with self Encryption key.
    return _decryptAtKeysWithSelfEncKey(
        decodedAtKeysData, atAuthRequest.authMode);
  }

  static AtAuthKeys _decryptAtKeysWithSelfEncKey(
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
}
