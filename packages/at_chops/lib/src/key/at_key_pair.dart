import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';
import 'package:crypton/crypton.dart';

/// Represents a key pair for asymmetric public-private key encryption
abstract class AtKeyPair extends AtEncryptionKey {
  AtKeyPair(AtPrivateKey atPrivateKey, AtPublicKey atPublicKey);
}

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
  late AtEncryptionPublicKey _atEncryptionPublicKey;
  late AtEncryptionPrivateKey _atEncryptionPrivateKey;
  late AsymmetricKey _asymmetricKey;

  AsymmetricKey get asymmetricKey => _asymmetricKey;

  AtEncryptionKeyPair(
      this._atEncryptionPublicKey, this._atEncryptionPrivateKey);
  String get publicKeyString => _atEncryptionPublicKey.publicKey;
  String get privateKeyString => _atEncryptionPrivateKey.privateKey;

  /// Generates a key pair based on [AsymmetricKey] passed.
  /// Generates [ECKeypair] if [AsymmetricKey.ec] is passed.
  /// Generates [RSAKeypair] if [AsymmetricKey.rsa] is passed.
  /// If no [AsymmetricKey] is passed [AsymmetricKey.rsa] key pair is generated
  AtEncryptionKeyPair.create({AsymmetricKey? asymmetricKey}) {
    switch (asymmetricKey) {
      case AsymmetricKey.ec:
        final ecKeyPair = ECKeypair.fromRandom();
        _atEncryptionPublicKey =
            AtEncryptionPublicKey(ecKeyPair.publicKey.toString());
        _atEncryptionPrivateKey =
            AtEncryptionPrivateKey(ecKeyPair.privateKey.toString());
        _asymmetricKey = AsymmetricKey.ec;
        break;
      case AsymmetricKey.rsa:
      default:
        final rsaKeypair = RSAKeypair.fromRandom();
        _atEncryptionPublicKey =
            AtEncryptionPublicKey(rsaKeypair.publicKey.toString());
        _atEncryptionPrivateKey =
            AtEncryptionPrivateKey(rsaKeypair.privateKey.toString());
        _asymmetricKey = AsymmetricKey.rsa;
    }
  }
}

enum AsymmetricKey { rsa, ec }
