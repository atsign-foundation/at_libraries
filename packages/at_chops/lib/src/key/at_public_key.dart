import 'package:at_chops/src/key/at_key_pair.dart';

/// Represents a public key from [AtKeyPair]
class AtPublicKey {
  late String _publicKey;
  AtPublicKey.fromString(this._publicKey);
  String get publicKey => _publicKey;
}
