import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';

/// Interface for encrypting and decrypting data. Check [DefaultEncryptionAlgo] for sample implementation.
abstract class AtEncryptionAlgorithm {
  /// Encrypts the passed bytes. Bytes are passed as [Uint8List]. Encode String data type to [Uint8List] using [utf8.encode].
  Uint8List encrypt(Uint8List plainData);

  /// Decrypts the passed encrypted bytes.
  Uint8List decrypt(Uint8List encryptedData);
}

/// Interface for data signing. Data is signed using private key from a key pair
/// Signed data signature is verified with public key of the key pair.
abstract class AtSigningAlgorithm {
  /// Pass a public private key pair. Any dart implementation of cryptographic algorithms can be used for generating key pair.
  /// Convert your key object to string and construct [AtSigningPublicKey] and [AtSigningPrivateKey].
  /// Refer [AtChopsUtil.generateSigningKeyPair()] for sample
  // AtSigningAlgorithm(AtKeyPair keyPair);

  /// Signs the data using [AtSigningPrivateKey] of [AtSigningKeyPair]
  Uint8List sign(Uint8List data, String privateKey);

  /// Verifies the data signature using [AtSigningPublicKey] of [AtSigningKeyPair]
  bool verify(Uint8List signedData, Uint8List signature, String publicKey);
}

/// Interface for hashing data. Refer [DefaultHash] for sample implementation.
abstract class AtHashingAlgorithm {
  /// Hashes the passed data
  String hash(Uint8List data);
}
