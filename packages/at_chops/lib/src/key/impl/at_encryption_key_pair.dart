import 'package:at_chops/src/key/at_key_pair.dart';

class AtEncryptionKeyPair extends AsymmetricKeyPair {
  AtEncryptionKeyPair.create(String publicKey, String privateKey)
      : super.create(publicKey, privateKey);
}
