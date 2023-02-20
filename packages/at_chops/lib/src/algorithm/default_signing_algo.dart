import 'dart:typed_data';

import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification using sha256 hash and atsign encryption keypair
class DefaultSigningAlgo implements AtSigningAlgorithm {
  final AtEncryptionKeyPair? _encryptionKeyPair;
  SigningAlgoType? _signingAlgoType;
  HashingAlgoType? _hashingAlgoType;
  DefaultSigningAlgo(this._encryptionKeyPair);

  @override
  Uint8List sign(Uint8List data) {
    if (_encryptionKeyPair == null) {
      throw AtException('encryption key pair not set for default signing algo');
    }
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeyPair!.atPrivateKey.privateKey);
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
  bool verify(Uint8List signedData, Uint8List signature, {String? publicKey}) {
    RSAPublicKey? rsaPublicKey;
    if (publicKey != null) {
      rsaPublicKey = RSAPublicKey.fromString(publicKey);
    } else if (_encryptionKeyPair != null) {
      rsaPublicKey =
          RSAPublicKey.fromString(_encryptionKeyPair!.atPublicKey.publicKey);
    } else {
      throw AtException(
          'Encryption key pair or public key not set for default signing algo');
    }
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
