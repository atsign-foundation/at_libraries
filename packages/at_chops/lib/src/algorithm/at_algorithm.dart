import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

/// Interface for encrypting and decrypting data. Check [DefaultEncryptionAlgo] for sample implementation.
abstract class AtEncryptionAlgorithm {
  /// Encrypts the passed bytes. Bytes are passed as [Uint8List]. Encode String data type to [Uint8List] using [utf8.encode].
  Uint8List encrypt(Uint8List plainData);

  /// Decrypts the passed encrypted bytes.
  Uint8List decrypt(Uint8List encryptedData);
}

/// Interface for symmetric encryption algorithms. Check [AESEncryptionAlgo] for sample implementation.
abstract class SymmetricEncryptionAlgorithm extends AtEncryptionAlgorithm {
  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector iv});
  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector iv});
}

/// Interface for data signing. Data is signed using private key from a key pair
/// Signed data signature is verified with public key of the key pair.
abstract class AtSigningAlgorithm {
  /// Signs the data using [AtPrivateKey] of [AsymmetricKeyPair]
  Uint8List sign(Uint8List data, int digestLength);

  /// Verifies the data signature using [AtPublicKey] of [AsymmetricKeyPair]
  bool verify(Uint8List signedData, Uint8List signature, int digestLength);
}

/// Interface for hashing data. Refer [DefaultHash] for sample implementation.
abstract class AtHashingAlgorithm {
  /// Hashes the passed data
  String hash(Uint8List data);
}
