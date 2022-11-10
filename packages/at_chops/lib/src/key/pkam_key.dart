import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';


class PkamPrivateKey implements AtPrivateKey {
  final String _pkamPrivateKey;
  PkamPrivateKey(this._pkamPrivateKey);
  String get privateKey => _pkamPrivateKey;
}

class PkamPublicKey implements AtPublicKey {
  final String _pkamPublicKey;
  PkamPublicKey(this._pkamPublicKey);
  String get publicKey => _pkamPublicKey;
}

class PkamKeyPair implements AtKeyPair {
  PkamKeyPair(PkamPublicKey pkamPublicKey, PkamPrivateKey pkamPrivateKey);
}
