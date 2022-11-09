import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class AtSigningPrivateKey implements AtPrivateKey {
  final String _signingPrivateKey;
  AtSigningPrivateKey(this._signingPrivateKey);
  String get privateKey => _signingPrivateKey;
}

class AtSigningPublicKey implements AtPublicKey {
  late String _signingPublicKey;
  AtSigningPublicKey(this._signingPublicKey);
  String get publicKey => _signingPublicKey;
}

class AtSigningKeyPair implements AtKeyPair {
  late AtSigningPublicKey signingPublicKey;
  late AtSigningPrivateKey signingPrivateKey;
  AtSigningKeyPair(AtSigningPublicKey signingPublicKey,
      AtSigningPrivateKey signingPrivateKey);
}
