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
  Uint8List encryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});
  String encryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});
  Uint8List decryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});
  String decryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv});
  Uint8List sign(Uint8List data, AtSigningAlgorithm signingAlgorithm);
  bool verify(Uint8List signedData, Uint8List signature,
      AtSigningAlgorithm signingAlgorithm);
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
