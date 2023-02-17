import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class DefaultSigningAlgo implements AtSigningAlgorithm {
  final AtEncryptionKeyPair _encryptionKeyPair;
  final SigningKeyType _signingKeyType;
  final String? verificationPublicKey;
  DefaultSigningAlgo(this._encryptionKeyPair, this._signingKeyType,
      {this.verificationPublicKey});

  @override
  Uint8List sign(Uint8List data, int digestLength) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeyPair.atPrivateKey.privateKey);
    return rsaPrivateKey.createSHA256Signature(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, int digestLength) {
    if (verificationPublicKey == null) {
      throw AtException('PublicKey is required to verify a digital signature');
    }
    final rsaPublicKey = RSAPublicKey.fromString(verificationPublicKey!);
    return rsaPublicKey.verifySHA256Signature(signedData, signature);
  }

  static int parseDigestLength(String signatureSpec) {
    return signatureSpec.split('/')[1] as int;
  }

  static String generateDigestSpec(int digestLength) {
    return 'SHA-2/$digestLength';
  }
}
