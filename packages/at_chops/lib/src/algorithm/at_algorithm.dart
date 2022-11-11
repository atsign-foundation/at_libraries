import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/key/aes_key.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/signing_key.dart';

/// Interface for encrypting and decrypting data. Check [DefaultEncryptionAlgo] for sample implementation.
abstract class AtEncryptionAlgorithm {
  /// [AtEncryptionKey] can be either symmetric (AES) or asymmetric (RSA public-private keypair).
  /// Refer [AtEncryptionKeyPair] and [AESKey] for implementation.
  AtEncryptionAlgorithm(AtEncryptionKey atEncryptionKey);

  /// Encrypts the passed bytes. Bytes are passed as [Uint8List]. Encode String data type to [Uint8List] using [utf8.encode].
  /// Optionally pass an initialisation vector for symmetric key encryption.
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv});

  /// Decrypts the passed encrypted bytes.
  /// Optionally pass an initialisation vector for symmetric key decryption.
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv});
}

/// Interface for data signing. Data is signed using private key from a key pair
/// Signed data signature is verified with public key of the key pair.
abstract class AtSigningAlgorithm {
  /// Pass a public private key pair. Any dart implementation of cryptographic algorithms can be used for generating key pair.
  /// Convert your key object to string and construct [AtSigningPublicKey] and [AtSigningPrivateKey].
  /// Refer [AtChopsUtil.generateSigningKeyPair()] for sample
  AtSigningAlgorithm(AtSigningKeyPair keyPair);

  /// Signs the data using [AtSigningPrivateKey] of [AtSigningKeyPair]
  Uint8List sign(Uint8List data);

  /// Verifies the data signature using [AtSigningPublicKey] of [AtSigningKeyPair]
  bool verify(Uint8List signedData, Uint8List signature);
}

/// Interface for hashing data. Refer [DefaultHash] for sample implementation.
abstract class AtHashingAlgorithm {
  /// Hashes the passed data
  String hash(Uint8List data);
}
