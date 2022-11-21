import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms or use the default implementation -
/// [DefaultHash] - uses MD5 for hashing
abstract class AtChops {
  final AtChopsKeys _atChopsKeys;

  AtChopsKeys get atChopsKeys => _atChopsKeys;

  AtChops(this._atChopsKeys);

  /// Encrypts the input bytes [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.encrypt] for default implementation of the encryption algorithm.
  Uint8List encryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm});

  /// Encrypts the input string [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.encrypt] for default implementation of the encryption algorithm.
  String encryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm});

  /// Decrypts the input bytes [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.decrypt] for default implementation of the encryption algorithm.
  /// Optionally pass an initialisation vector [iv] that was agreed upon by the sender.
  Uint8List decryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm});

  /// Decrypts the input string [data] using an [encryptionAlgorithm].
  /// Refer to [DefaultEncryptionAlgo.decrypt] for default implementation of the encryption algorithm.
  String decryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm});

  /// Sign the input [data] using [AtSigningPrivateKey] of [AtSigningKeyPair].
  /// Refer to [DefaultSigningAlgo.sign] for default implementation of data signing.
  Uint8List sign(Uint8List data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Verify signed data using [AtSigningPublicKey] of [AtSigningKeyPair].
  /// Refer to [DefaultSigningAlgo.verify] for default implementation of data verification.
  bool verify(
      Uint8List signedData, Uint8List signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Create a string hash of input [signedData] using a [hashingAlgorithm].
  /// Refer to [DefaultHash] for default implementation of hashing.
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
