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
  late AtSigningPublicKey _signingPublicKey;
  late AtSigningPrivateKey _signingPrivateKey;
  AtSigningKeyPair(this._signingPublicKey, this._signingPrivateKey);
  AtSigningPublicKey get publicKey => _signingPublicKey;
  AtSigningPrivateKey get privateKey => _signingPrivateKey;
}
