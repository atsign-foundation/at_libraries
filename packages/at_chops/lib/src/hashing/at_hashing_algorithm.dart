import 'dart:async';

import 'package:at_chops/src/hashing/md5_hashing_algo.dart';
import 'package:at_commons/at_commons.dart';

/// Interface for hashing data. Refer [DefaultHash] for sample implementation.
abstract class AtHashingAlgorithm<K, V> {
  /// Hashes the passed data
  FutureOr<V> hash(K data, {covariant HashParams? hashParams});
}

class HashParams {}

class DefaultHashingAlgo extends Md5HashingAlgo {}

enum HashingAlgoType {
  sha256,
  sha512,
  md5,
  argon2id;

  static HashingAlgoType fromString(String name) {
    return HashingAlgoType.values.firstWhere(
        (algo) => algo.name == name.toLowerCase(),
        orElse: () => throw AtException('Invalid hashing algo type'));
  }
}
