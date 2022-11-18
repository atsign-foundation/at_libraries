import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:crypton/crypton.dart';

class DefaultSigningAlgo implements AtSigningAlgorithm {
  @override
  Uint8List sign(Uint8List data, String privateKey) {
    final rsaPrivateKey = RSAPrivateKey.fromString(privateKey);
    return rsaPrivateKey.createSHA256Signature(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, String publicKey) {
    final rsaPublicKey = RSAPublicKey.fromString(publicKey);
    return rsaPublicKey.verifySHA256Signature(signedData, signature);
  }
}
