import 'package:at_chops/src/key/at_key_pair.dart';

class AtSigningKeyPair extends AsymmetricKeyPair {
  AtSigningKeyPair.create(String publicKey, String privateKey)
      : super.create(publicKey, privateKey);
}
