import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

class AtEncryptionPrivateKey implements AtPrivateKey {
  late String _atEncryptionPrivateKey;
  AtEncryptionPrivateKey.fromString(String privateKey) {
    _atEncryptionPrivateKey = privateKey;
  }
  String get privateKey => _atEncryptionPrivateKey;
}

class AtEncryptionPublicKey implements AtPublicKey {
  late String _atEncryptionPublicKey;
  AtEncryptionPublicKey.fromString(String publicKey) {
    _atEncryptionPublicKey = publicKey;
  }
  String get publicKey => _atEncryptionPublicKey;
}

class AtEncryptionKeyPair implements AtKeyPair {
  late AtEncryptionPublicKey atEncryptionPublicKey;
  late AtEncryptionPrivateKey atEncryptionPrivateKey;
  AtEncryptionKeyPair(AtEncryptionPublicKey atEncryptionPublicKey,
      AtEncryptionPrivateKey atEncryptionPrivateKey);
}
