import 'package:at_auth/src/auth_constants.dart' as auth_constants;

/// Holder for different encryption keys that will be stored in .atKeys file.
/// Apkam symmetric key, enrollmentId and defaultSelfEncryptionKey will be stored in unencrypted format in .atKeys file.
/// All other values will be encrypted before saving to .atKeys file.
class AtSecurityKeys {
  String? apkamPublicKey;
  String? apkamPrivateKey;
  String? defaultEncryptionPublicKey;
  String? defaultEncryptionPrivateKey;
  String? defaultSelfEncryptionKey;
  String? apkamSymmetricKey;
  String? enrollmentId;

  Map<String, String?> toMap() {
    var keysMap = <String, String?>{};
    keysMap[auth_constants.apkamPrivateKey] = apkamPrivateKey;
    keysMap[auth_constants.apkamPublicKey] = apkamPublicKey;
    keysMap[auth_constants.defaultEncryptionPrivateKey] =
        defaultEncryptionPrivateKey;
    keysMap[auth_constants.defaultEncryptionPublicKey] =
        defaultEncryptionPublicKey;
    keysMap[auth_constants.defaultSelfEncryptionKey] = defaultSelfEncryptionKey;
    keysMap[auth_constants.apkamSymmetricKey] = apkamSymmetricKey;
    keysMap[auth_constants.apkamEnrollmentId] = enrollmentId;
    return keysMap;
  }
}
