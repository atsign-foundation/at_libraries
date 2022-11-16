import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms or use the default implementation -
/// [DefaultEncryptionAlgo] - uses symmetric AES encryption/decryption
/// [DefaultSigningAlgo] - uses RSA sha256 signature for data signing and verification
/// [DefaultHash] - uses MD5 for hashing
abstract class AtChops {
  /// Encrypts the input bytes [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.encrypt] for default implementation of the encryption algorithm.
  /// Optionally pass an initialisation vector [iv] for symmetric encryption.
  Uint8List encryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});

  /// Encrypts the input string [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.encrypt] for default implementation of the encryption algorithm.
  /// Optionally pass an initialisation vector [iv] for symmetric encryption.
  String encryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});

  /// Decrypts the input bytes [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.decrypt] for default implementation of the encryption algorithm.
  /// Optionally pass an initialisation vector [iv] that was agreed upon by the sender.
  Uint8List decryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});

  /// Decrypts the input string [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.decrypt] for default implementation of the encryption algorithm.
  /// Optionally pass an initialisation vector [iv] that was agreed upon by the sender.
  String decryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});

  /// Sign the input [data] using [AtSigningPrivateKey] of [AtSigningKeyPair].
  /// Refer to [DefaultSigningAlgo.sign] for default implementation of data signing.
  Uint8List sign(Uint8List data, AtSigningAlgorithm signingAlgorithm);

  /// Verify signed data using [AtSigningPublicKey] of [AtSigningKeyPair].
  /// Refer to [DefaultSigningAlgo.verify] for default implementation of data verification.
  bool verify(Uint8List signedData, Uint8List signature,
      AtSigningAlgorithm signingAlgorithm);

  /// Create a string hash of input [signedData] using a [hashingAlgorithm].
  /// Refer to [DefaultHash] for default implementation of hashing.
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
