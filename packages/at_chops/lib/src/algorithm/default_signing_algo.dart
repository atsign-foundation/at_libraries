import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/at_key_pair.dart';

class DefaultSigningAlgo implements AtSigningAlgorithm {
  late AtKeyPair _atSigningKeyPair;
  DefaultSigningAlgo(this._atSigningKeyPair);
  @override
  Uint8List sign(Uint8List data) {
    return _atSigningKeyPair.sign(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    return _atSigningKeyPair.verify(signedData, signature);
  }
}
