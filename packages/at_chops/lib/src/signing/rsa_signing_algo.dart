import 'dart:typed_data';

import 'package:at_chops/src/hashing/hashing.dart';
import 'package:at_chops/src/key/at_rsa_key_pair.dart';
import 'package:at_chops/src/signing/at_signing_algorithm.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification using atsign encryption keypair
/// Allowed algorithms are listed in [SigningAlgoType] and [HashingAlgoType]
class RSASigningAlgo implements AtSigningAlgorithm {
  final AtRSAKeyPair? _encryptionKeyPair;
  final HashingAlgoType _hashingAlgoType;
  final String errorMessageKeyname = "Encryption";

  RSASigningAlgo(this._encryptionKeyPair, this._hashingAlgoType);

  @override
  Uint8List sign(Uint8List data) {
    if (_encryptionKeyPair == null) {
      throw AtSigningException('$errorMessageKeyname key pair not set');
    }
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeyPair!.atPrivateKey.privateKey);
    switch (_hashingAlgoType) {
      case HashingAlgoType.sha256:
        return rsaPrivateKey.createSHA256Signature(data);
      case HashingAlgoType.sha512:
        return rsaPrivateKey.createSHA512Signature(data);
      default:
        throw AtSigningException(
            'Hashing algo $_hashingAlgoType is invalid/not supported');
    }
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, {String? publicKey}) {
    RSAPublicKey? rsaPublicKey;
    if (publicKey != null) {
      rsaPublicKey = RSAPublicKey.fromString(publicKey);
    } else if (_encryptionKeyPair != null) {
      rsaPublicKey =
          RSAPublicKey.fromString(_encryptionKeyPair!.atPublicKey.publicKey);
    } else {
      throw AtSigningVerificationException(
          '$errorMessageKeyname key pair or public key not set for default signing algo');
    }
    switch (_hashingAlgoType) {
      case HashingAlgoType.sha256:
        return rsaPublicKey.verifySHA256Signature(signedData, signature);
      case HashingAlgoType.sha512:
        return rsaPublicKey.verifySHA512Signature(signedData, signature);
      default:
        throw AtSigningVerificationException(
            'Invalid hashing algo $_hashingAlgoType provided');
    }
  }
}
