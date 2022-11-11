import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

/// Represents a key pair for asymmetric public-private key encryption
abstract class AtKeyPair extends AtEncryptionKey {
  AtKeyPair(AtPrivateKey atPrivateKey, AtPublicKey atPublicKey);
}
