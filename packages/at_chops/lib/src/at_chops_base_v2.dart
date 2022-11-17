import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_symmetric_key.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms or use the default implementation -
abstract class AtChopsV2 {
  /// Encrypts the input data using [AtPublicKey] of [AtKeyPair]
  /// Check [AtRSAKeyPair] for sample implementation of [AtKeyPair]
  Uint8List encrypt(Uint8List data, AtKeyPair atKeyPair);

  /// Decrypts the input data using [AtPrivateKey] of [AtKeyPair]
  Uint8List decrypt(Uint8List data, AtKeyPair atKeyPair);

  /// Sings the data using [AtPrivateKey] of [AtKeyPair]
  Uint8List sign(Uint8List data, AtKeyPair atKeyPair);

  /// Verifies [signature] of [signedData] using [AtPublicKey] of [AtKeyPair]
  bool verify(Uint8List signedData, Uint8List signature, AtKeyPair atKeyPair);

  /// Encrypts data using [AtSymmetricKey] and an optional [InitialisationVector]
  Uint8List encryptSymmetric(Uint8List data, AtSymmetricKey atSymmetricKey,
      {InitialisationVector? iv});

  /// Decrypts data using [AtSymmetricKey] and an optional [InitialisationVector]
  Uint8List decryptSymmetric(
      Uint8List encryptedData, AtSymmetricKey atSymmetricKey,
      {InitialisationVector? iv});
  // String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
