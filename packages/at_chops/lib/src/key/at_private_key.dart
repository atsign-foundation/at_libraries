import 'dart:typed_data';

/// Represents a private key from [AtKeyPair]
abstract class AtPrivateKey {
  AtPrivateKey.fromString(String atPrivateKey);
  Uint8List createSHA256Signature(Uint8List message);

  /// Decrypts the passed encrypted bytes.
  Uint8List decrypt(Uint8List encryptedData);
}
