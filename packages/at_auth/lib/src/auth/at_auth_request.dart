import 'package:at_auth/src/keys/at_auth_keys.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_auth/src/auth_constants.dart' as auth_constants;

class AtAuthRequest {
  String atSign;

  AtAuthRequest(this.atSign);

  String? enrollmentId;
  AtAuthKeys? atAuthKeys;
  String rootDomain = 'root.atsign.org';
  int rootPort = 64;
  PkamAuthMode authMode = PkamAuthMode.keysFile;
  String? atKeysFilePath;
  Map<String, dynamic>? encryptedKeysMap;

  /// public key id from secure element if [authMode] is [PkamAuthMode.sim]
  String? publicKeyId;

  AtAuthKeys getDecryptedKeys() {
    if (encryptedKeysMap == null) {
      return AtAuthKeys();
    }
    AtAuthKeys atAuthKeys = AtAuthKeys();
    String decryptionKey =
        encryptedKeysMap![auth_constants.defaultSelfEncryptionKey]!;
    AtChops atChops =
        AtChopsImpl(AtChopsKeys()..selfEncryptionKey = AESKey(decryptionKey));
    atAuthKeys.defaultEncryptionPublicKey = atChops
        .decryptString(
            encryptedKeysMap![auth_constants.defaultEncryptionPublicKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey',
            iv: AtChopsUtil.generateIVLegacy())
        .result;
    atAuthKeys.defaultEncryptionPrivateKey = atChops
        .decryptString(
            encryptedKeysMap![auth_constants.defaultEncryptionPrivateKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey',
            iv: AtChopsUtil.generateIVLegacy())
        .result;
    atAuthKeys.defaultSelfEncryptionKey = decryptionKey;
    atAuthKeys.apkamPublicKey = atChops
        .decryptString(encryptedKeysMap![auth_constants.apkamPublicKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
        .result;
    atAuthKeys.apkamPrivateKey = atChops
        .decryptString(encryptedKeysMap![auth_constants.apkamPrivateKey]!,
            EncryptionKeyType.aes256,
            keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
        .result;

    atAuthKeys.apkamSymmetricKey =
        encryptedKeysMap![auth_constants.apkamSymmetricKey];
    atAuthKeys.enrollmentId = encryptedKeysMap![AtConstants.enrollmentId];
    return atAuthKeys;
  }
}
