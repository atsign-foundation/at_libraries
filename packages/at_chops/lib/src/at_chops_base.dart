import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_chops/src/metadata/at_signing_input.dart';
import 'package:at_chops/src/metadata/encryption_result.dart';
import 'package:at_chops/src/metadata/signing_result.dart';
import 'package:at_chops/src/util/at_signature_verification_result.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms. Otherwise default implementation of specific algorithms will be used.
abstract class AtChops {
  final AtChopsKeys _atChopsKeys;

  AtChopsKeys get atChopsKeys => _atChopsKeys;

  AtChops(this._atChopsKeys);

  /// Encrypts the input bytes [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult encryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Encrypts the input string [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult encryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input bytes [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult decryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Decrypts the input string [data] using an [encryptionAlgorithm] and returns [AtEncryptionResult].
  /// If [encryptionKeyType] is [EncryptionKeyType.rsa2048] then [encryptionAlgorithm] will be set to [DefaultEncryptionAlgo]
  /// [keyName] specifies which key pair to use if user has multiple key pairs configured.
  /// If [keyName] is not passed default encryption/decryption keypair from .atKeys file will be used.
  AtEncryptionResult decryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv});

  /// Sign the input bytes [data] using a [signingAlgorithm].
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  AtSigningResult signBytes(Uint8List data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm, int digestLength});

  /// Verify the [signature] of bytes [data] using a [signingAlgorithm]
  /// If [signingKeyType] is [SigningKeyType.pkamSha256] then [signingAlgorithm] will be set to [PkamSigningAlgo]
  /// If [signingKeyType] is [SigningKeyType.signingSha256] then [signingAlgorithm] will be set to [DefaultSigningAlgo]
  AtSigningResult verifySignatureBytes(
      Uint8List data, Uint8List signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm, int digestLength});

  ///Method that generates dataSignature for String [data] using an [RSAPrivateKey]
  ///Required Inputs:
  /// 1) String data that needs to be signed
  /// 2) Preferred length of signature
  ///Output: base64Encoded signature generated using [algorithm] and [digestLength]
  @Deprecated('Use sign() instead')
  AtSigningResult signString(
      String data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? atSingingAlgorithm});

  ///Verifies dataSignature in [data] to [signature] using [publicKey]
  ///Required inputs:
  ///1) data that needs to be verified using [signature]
  ///2) signature to be verified in base64Encoded String format
  ///3) DigestLength used to generate [signature]
  ///Output:
  ///Case verified - Returns [AtSignatureVerificationResult] object with [AtSignatureVerificationResult.isVerified] set to true
  ///case NotVerified - Returns [AtSignatureVerificationResult] object with [AtSignatureVerificationResult.isVerified] set to false
  ///and the exception is stored in [AtSignatureVerificationResult.exception]
  @Deprecated('Use verify() instead')
  AtSigningResult verifyStringSignature(String data, String signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? atSigningAlgorithm});

  ///Method that generates dataSignature for type[AtSignatureInput] using an [RSAPrivateKey]
  ///Required Inputs:
  /// 1) [AtSigningInput] object with all parameters specified
  ///Output:
  ///[AtSignature] object containing [signature], [signatureTimestamp] and [signedBy]
  ///signature is a base64Encoded String generated using algorithm and digestLength specified in [AtSigningInput]
  AtSigningResult sign(AtSigningInput signingInput);

  ///Method that verifies dataSignature of object type [AtSignature] using [RSAPublicKey]
  ///Required inputs:
  ///1) [AtSignature] object containing all required parameters
  ///Verifies signature in [AtSignature.signature] to [AtSignature.actualText]
  AtSigningResult verify(AtSigningInput signingInput);

  /// Create a string hash of input [signedData] using a [hashingAlgorithm].
  /// Refer to [DefaultHash] for default implementation of hashing.
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
