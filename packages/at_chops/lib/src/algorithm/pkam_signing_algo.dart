import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class PkamSigningAlgo implements AtSigningAlgorithm {
  final AtPkamKeyPair _pkamKeyPair;
  final SigningKeyType _signingKeyType;
  PkamSigningAlgo(this._pkamKeyPair, this._signingKeyType);

  @override
  Uint8List sign(Uint8List data, int digestLength) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_pkamKeyPair.atPrivateKey.privateKey);
    switch(digestLength){
      case 256:
        return rsaPrivateKey.createSHA256Signature(data);
      case 512:
        return rsaPrivateKey.createSHA512Signature(data);
      default:
        throw AtException('Invalid digestLength provided');
    }

  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, int digestLength) {
    final rsaPublicKey =
        RSAPublicKey.fromString(_pkamKeyPair.atPublicKey.publicKey);
    switch(digestLength){
      case 256:
        return rsaPublicKey.verifySHA256Signature(signedData, signature);
      case 512:
        return rsaPublicKey.verifySHA512Signature(signedData, signature);
      default:
        throw AtException('Invalid digestLength provided');
    }
  }
}
