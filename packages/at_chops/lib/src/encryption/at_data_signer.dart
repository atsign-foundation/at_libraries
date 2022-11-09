import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class AtDataSigner {
  final AtSigningAlgorithm _atSigningAlgorithm;
  AtDataSigner(this._atSigningAlgorithm);

  Uint8List sign(Uint8List data) {
    return _atSigningAlgorithm.sign(data);
  }

  bool verify(Uint8List signedData, Uint8List signature) {
    return _atSigningAlgorithm.verify(signedData, signature);
  }
}
