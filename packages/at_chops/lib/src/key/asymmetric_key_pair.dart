import 'dart:typed_data';

/// Represents a key pair for asymmetric public-private key encryption/decryption
abstract class AsymmetricKeyPair<Pub extends AtPublicKey,
    Priv extends AtPrivateKey> {
  final Priv _atPrivateKey;
  final Pub _atPublicKey;

  AsymmetricKeyPair(this._atPublicKey, this._atPrivateKey);

  Pub get atPublicKey => _atPublicKey;
  Priv get atPrivateKey => _atPrivateKey;
}

/// Represents a private key from [AtKeyPair]
abstract class AtPrivateKey {
  String get privateKey;
  Uint8List get raw;

  @override
  String toString() => privateKey;
}

/// Represents a public key from [AtKeyPair]
abstract class AtPublicKey {
  String get publicKey;
  Uint8List get raw;

  @override
  String toString() => publicKey;
}
