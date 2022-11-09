import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class AtSigningPrivateKey implements AtPrivateKey {
  late String _signingPrivateKey;
  AtSigningPrivateKey.fromString(String privateKey) {
    _signingPrivateKey = privateKey;
  }
  String get privateKey => _signingPrivateKey;
}

class AtSigningPublicKey implements AtPublicKey {
  late String _signingPublicKey;
  AtSigningPublicKey.fromString(String publicKey) {
    _signingPublicKey = publicKey;
  }
  String get publicKey => _signingPublicKey;
}

class AtSigningKeyPair implements AtKeyPair {
  late AtSigningPublicKey signingPublicKey;
  late AtSigningPrivateKey signingPrivateKey;
  AtSigningKeyPair(AtSigningPublicKey signingPublicKey,
      AtSigningPrivateKey signingPrivateKey);
}
