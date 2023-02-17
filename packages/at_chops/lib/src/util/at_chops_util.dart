import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/aes_key.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';

class AtChopsUtil {
  /// Generates a random initialisation vector from a given length
  /// Length must be 0 to 16
  /// #TODO explain about implications of changing length
  static InitialisationVector generateIV(int length) {
    final iv = IV.fromSecureRandom(length);
    return InitialisationVector(iv.bytes);
  }

  /// Generates RSA keypair with default size 2048 bits
  static RSAKeypair generateRSAKeyPair({int keySize = 2048}) {
    return RSAKeypair.fromRandom(keySize: keySize);
  }

  /// Generates AtEncryption asymmetric keypair with default size 2048 bits
  static AtEncryptionKeyPair generateAtEncryptionKeyPair({int keySize = 2048}) {
    final rsaKeyPair = RSAKeypair.fromRandom(keySize: keySize);
    return AtEncryptionKeyPair.create(
        rsaKeyPair.publicKey.toString(), rsaKeyPair.privateKey.toString());
  }

  /// Generates AtEncryption asymmetric keypair with default size 2048 bits
  static AtPkamKeyPair generateAtPkamKeyPair({int keySize = 2048}) {
    final rsaKeyPair = RSAKeypair.fromRandom(keySize: keySize);
    return AtPkamKeyPair.create(
        rsaKeyPair.publicKey.toString(), rsaKeyPair.privateKey.toString());
  }

  /// Generates EC keypair
  static ECKeypair generateECKeyPair() {
    return ECKeypair.fromRandom();
  }

  static SymmetricKey generateSymmetricKey(EncryptionKeyType keyType) {
    switch (keyType) {
      case EncryptionKeyType.aes128:
        return AESKey.generate(16);
      case EncryptionKeyType.aes192:
        return AESKey.generate(24);
      case EncryptionKeyType.aes256:
        return AESKey.generate(32);
      default:
        return AESKey.generate(32);
    }
  }
}
