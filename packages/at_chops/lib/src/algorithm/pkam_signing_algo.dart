import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class PkamSigningAlgo implements AtSigningAlgorithm {
  final AtPkamKeyPair _pkamKeyPair;
  final SigningKeyType _signingKeyType;
  PkamSigningAlgo(this._pkamKeyPair, this._signingKeyType);

  @override
  Uint8List sign(Uint8List data) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_pkamKeyPair.atPrivateKey.privateKey);
    return rsaPrivateKey.createSHA256Signature(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    final rsaPublicKey =
        RSAPublicKey.fromString(_pkamKeyPair.atPublicKey.publicKey);
    return rsaPublicKey.verifySHA256Signature(signedData, signature);
  }
}
