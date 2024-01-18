import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/rsa_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_chops/src/metadata/at_signing_input.dart';
import 'package:at_chops/src/metadata/encryption_result.dart';
import 'package:at_chops/src/metadata/signing_result.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms. Otherwise default implementation of specific algorithms will be used.
abstract class AtChops {
  final AtChopsKeys _atChopsKeys;

  AtChopsKeys get atChopsKeys => _atChopsKeys;

  AtChops(this._atChopsKeys);

  /// Encrypts the input bytes [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [RsaEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult encryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Encrypts the input string [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [RsaEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult encryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input bytes [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [RsaEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult decryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input string [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [RsaEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult decryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Compute data signature using the private key from a key pair
  /// Input has to be set using [AtSigningInput] object
  /// Please refer to [AtSigningInput] to create a valid input instance
  /// [AtSigningResult.result] should be base64Encoded
  AtSigningResult sign(AtSigningInput signingInput);

  /// Verifies the signature computed for inpuat data using the public key from a key pair
  /// Input has to set using [AtSigningVerificationInput] object
  /// Please refer to [AtSigningVerificationInput] docs to create a valid input instance
  /// [AtSigningVerificationInput.result] should be base64Decoded if [AtSigningResult.result] is base64Encoded
  AtSigningResult verify(AtSigningVerificationInput verifyInput);

  /// Create a hash of input [signedData] using a [hashingAlgorithm].
  /// Refer to [DefaultHash] for default implementation of hashing.
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);

  /// Reads a public key from a secure element or any other source
  /// Clients can implement this method if want to use a different keypair for pkam authentication.
  /// e.g. Secure element can be a SIM card with an IOTSafe compliant app with a key pair preinstalled.
  String readPublicKey(String publicKeyId);
}
