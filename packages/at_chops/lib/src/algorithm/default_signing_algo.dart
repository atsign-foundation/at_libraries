import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/signing_key.dart';
import 'package:crypton/crypton.dart';

class DefaultSigningAlgo implements AtSigningAlgorithm {
  late AtSigningKeyPair _atSigningKeyPair;
  DefaultSigningAlgo(this._atSigningKeyPair);
  @override
  Uint8List sign(Uint8List data) {
    var privateKey = RSAPrivateKey.fromString(
        _atSigningKeyPair.signingPrivateKey.privateKey);
    var dataSignature = privateKey.createSHA256Signature(data);
    return dataSignature;
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    var publicKey =
        RSAPublicKey.fromString(_atSigningKeyPair.signingPublicKey.publicKey);
    return publicKey.verifySHA256Signature(signedData, signature);
  }
}
