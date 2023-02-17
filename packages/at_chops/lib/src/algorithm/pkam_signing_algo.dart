import 'dart:typed_data';

import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class PkamSigningAlgo implements AtSigningAlgorithm {
  final AtPkamKeyPair _pkamKeyPair;
  SigningAlgoType? _signingAlgoType;
  HashingAlgoType? _hashingAlgoType;
  PkamSigningAlgo(this._pkamKeyPair);

  @override
  Uint8List sign(Uint8List data) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_pkamKeyPair.atPrivateKey.privateKey);
    _hashingAlgoType ??= HashingAlgoType.sha256; //default to sha256
    switch (_hashingAlgoType) {
      case HashingAlgoType.sha256:
        return rsaPrivateKey.createSHA256Signature(data);
      case HashingAlgoType.sha512:
        return rsaPrivateKey.createSHA512Signature(data);
      default:
        throw AtException('Invalid hashing algo $_hashingAlgoType provided');
    }
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    final rsaPublicKey =
        RSAPublicKey.fromString(_pkamKeyPair.atPublicKey.publicKey);
    _hashingAlgoType ??= HashingAlgoType.sha256;
    switch (_hashingAlgoType) {
      case HashingAlgoType.sha256:
        return rsaPublicKey.verifySHA256Signature(signedData, signature);
      case HashingAlgoType.sha512:
        return rsaPublicKey.verifySHA512Signature(signedData, signature);
      default:
        throw AtException('Invalid hashing algo $_hashingAlgoType provided');
    }
  }

  @override
  void setHashingAlgoType(HashingAlgoType? hashingAlgoType) {
    _hashingAlgoType = hashingAlgoType;
  }

  @override
  void setSigningAlgoType(SigningAlgoType? signingAlgoType) {
    _signingAlgoType = signingAlgoType;
  }
}
