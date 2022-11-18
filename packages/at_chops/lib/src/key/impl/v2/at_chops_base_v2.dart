import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/default_hashing_algo.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';

/// Base class for all Cryptographic and Hashing Operations. Callers have to either implement
/// specific encryption, signing or hashing algorithms or use the default implementation -
abstract class AtChopsV2 {
  Uint8List encrypt(Uint8List data, AtKeyPair atKeyPair);

  Uint8List decrypt(Uint8List data, AtKeyPair atKeyPair);

  Uint8List sign(Uint8List data, AtKeyPair atKeyPair);

  bool verify(Uint8List signedData, Uint8List signature, AtKeyPair atKeyPair);

// String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}