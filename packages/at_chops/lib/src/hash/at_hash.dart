import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class AtHash {
  final AtHashingAlgorithm _atHashingAlgorithm;
  AtHash(this._atHashingAlgorithm);
  String hash(Uint8List data) {
    return _atHashingAlgorithm.hash(data);
  }
}
