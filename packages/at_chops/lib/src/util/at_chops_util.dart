import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/signing_key.dart';
import 'package:crypton/crypton.dart';
import 'package:encrypt/encrypt.dart';

class AtChopsUtil {
  /// Generates an AES key for symmetric encryption.
  /// Length must be 16(128  bit)/24 (192 bit)/32 (256 bit)
  /// #TODO find out how the length corresponds to 128,192 ans 256 bit
  static String generateAESKey(int length) {
    var aesKey = AES(Key.fromSecureRandom(length));
    var keyString = aesKey.key.base64;
    return keyString;
  }

  /// Generates a random initialisation vector from a given length
  /// Length must be 0 to 16
  /// #TODO explain about implications of changing length
  static InitialisationVector generateIV(int length) {
    final iv = IV.fromSecureRandom(length);
    return InitialisationVector(iv.bytes);
  }

  static AtSigningKeyPair generateSigningKeyPair() {
    var rsaKeypair = RSAKeypair.fromRandom();
    final publicKey = AtSigningPublicKey(rsaKeypair.publicKey.toString());
    final privateKey = AtSigningPrivateKey(rsaKeypair.privateKey.toString());
    return AtSigningKeyPair(publicKey, privateKey);
  }

  static AtEncryptionKeyPair generateEncryptionKeyPair() {
    var rsaKeypair = RSAKeypair.fromRandom();
    final publicKey = AtEncryptionPublicKey(rsaKeypair.publicKey.toString());
    final privateKey = AtEncryptionPrivateKey(rsaKeypair.privateKey.toString());
    return AtEncryptionKeyPair(publicKey, privateKey);
  }
}