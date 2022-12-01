import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/key_type.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms. Otherwise default implementation of specific algorithms will be used.
abstract class AtChops {
  final AtChopsKeys _atChopsKeys;

  AtChopsKeys get atChopsKeys => _atChopsKeys;

  AtChops(this._atChopsKeys);

  /// Encrypts the input bytes [data] using an [encryptionAlgorithm].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  Uint8List encryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Encrypts the input string [data] using an [encryptionAlgorithm].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  String encryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input bytes [data] using an [encryptionAlgorithm].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  Uint8List decryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input string [data] using an [encryptionAlgorithm].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  String decryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Sign the input bytes [data] using a [signingAlgorithm].
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  Uint8List signBytes(Uint8List data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Verify the [signature] of bytes [data] using a [signingAlgorithm]
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  bool verifySignatureBytes(
      Uint8List data, Uint8List signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Sign the input string [data] using a [signingAlgorithm].
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  String signString(String data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Verify the [signature] of string [data] using a [signingAlgorithm]
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  bool verifySignatureString(
      String data, String signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm});

  /// Create a string hash of input [signedData] using a [hashingAlgorithm].
  /// Refer to [DefaultHash] for default implementation of hashing.
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
