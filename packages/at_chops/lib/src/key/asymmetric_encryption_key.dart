import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class AtEncryptionPrivateKey implements AtPrivateKey {
  final String _atEncryptionPrivateKey;
  AtEncryptionPrivateKey(this._atEncryptionPrivateKey);
  String get privateKey => _atEncryptionPrivateKey;
}

class AtEncryptionPublicKey implements AtPublicKey {
  final String _atEncryptionPublicKey;
  AtEncryptionPublicKey(this._atEncryptionPublicKey);
  String get publicKey => _atEncryptionPublicKey;
}

class AtEncryptionKeyPair implements AtKeyPair {
  final AtEncryptionPublicKey _atEncryptionPublicKey;
  final AtEncryptionPrivateKey _atEncryptionPrivateKey;
  AtEncryptionKeyPair(
      this._atEncryptionPublicKey, this._atEncryptionPrivateKey);
  String get publicKeyString => _atEncryptionPublicKey.publicKey;
  String get privateKeyString => _atEncryptionPrivateKey.privateKey;
}
