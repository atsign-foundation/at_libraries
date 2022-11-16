import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/signing_key.dart';
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

  static AtSigningKeyPair generateSigningKeyPair() {
    var rsaKeypair = RSAKeypair.fromRandom();
    final publicKey = AtSigningPublicKey(rsaKeypair.publicKey.toString());
    final privateKey = AtSigningPrivateKey(rsaKeypair.privateKey.toString());
    return AtSigningKeyPair(publicKey, privateKey);
  }
}
