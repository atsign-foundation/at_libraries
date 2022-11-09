import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class PkamPrivateKey implements AtPrivateKey {
  late String _pkamPrivateKey;
  PkamPrivateKey.fromString(String privateKey) {
    _pkamPrivateKey = privateKey;
  }
}

class PkamPublicKey implements AtPublicKey {
  late String _pkamPublicKey;
  PkamPublicKey.fromString(String publicKey) {
    _pkamPublicKey = publicKey;
  }
}

class PkamKeyPair implements AtKeyPair {
  PkamKeyPair(PkamPublicKey pkamPublicKey, PkamPrivateKey pkamPrivateKey);
}
