import 'dart:typed_data';

import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

/// Represents a key pair for asymmetric public-private key encryption
abstract class AtKeyPair implements AtEncryptionKey {
  final AtPrivateKey _atPrivateKey;
  final AtPublicKey _atPublicKey;
  AtKeyPair(this._atPrivateKey, this._atPublicKey);
  /// Create SHA256 signature of the message using [AtPrivateKey]
  Uint8List sign(Uint8List message) {
    return _atPrivateKey.createSHA256Signature(message);
  }

  /// Decrypts the passed encrypted bytes using [AtPrivateKey]
  Uint8List decrypt(Uint8List encryptedData) {
    return _atPrivateKey.decrypt(encryptedData);
  }

  /// Verifies SHA256 signature of [message] using [AtPublicKey]
  bool verify(Uint8List message, Uint8List signature) {
    return _atPublicKey.verifySHA256Signature(message, signature);
  }

  /// Encrypts the passed bytes using [AtPublicKey]
  Uint8List encrypt(Uint8List data) {
    return _atPublicKey.encrypt(data);
  }
}