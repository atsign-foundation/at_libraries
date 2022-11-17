import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:crypton/crypton.dart';

class DefaultSigningAlgo implements AtSigningAlgorithm {
  final RSAKeypair _rsaKeypair;
  DefaultSigningAlgo(this._rsaKeypair);
  @override
  Uint8List sign(Uint8List data) {
    return _rsaKeypair.privateKey.createSHA256Signature(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    return _rsaKeypair.publicKey.verifySHA256Signature(signedData, signature);
  }
}
