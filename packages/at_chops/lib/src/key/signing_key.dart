import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class SigningPrivateKey implements AtPrivateKey {
  late String _signingPrivateKey;
  SigningPrivateKey.fromString(String privateKey) {
    _signingPrivateKey = privateKey;
  }
}

class SigningPublicKey implements AtPublicKey {
  late String _signingPublicKey;
  SigningPublicKey.fromString(String publicKey) {
    _signingPublicKey = publicKey;
  }
}

class SigningKeyPair implements AtKeyPair {
  SigningKeyPair(
      SigningPublicKey signingPublicKey, SigningPrivateKey signingPrivateKey);
}
