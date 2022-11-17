import 'package:at_chops/src/algorithm/at_iv.dart';
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

  /// Generates EC keypair
  static ECKeypair generateECKeyPair() {
    return ECKeypair.fromRandom();
  }
}
