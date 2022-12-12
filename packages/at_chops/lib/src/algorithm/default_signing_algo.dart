import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:crypton/crypton.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class DefaultSigningAlgo implements AtSigningAlgorithm {
  final AtEncryptionKeyPair _encryptionKeyPair;
  final SigningKeyType _signingKeyType;
  DefaultSigningAlgo(this._encryptionKeyPair, this._signingKeyType);

  @override
  Uint8List sign(Uint8List data) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeyPair.atPrivateKey.privateKey);
    return rsaPrivateKey.createSHA256Signature(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature) {
    final rsaPublicKey =
        RSAPublicKey.fromString(_encryptionKeyPair.atPublicKey.publicKey);
    return rsaPublicKey.verifySHA256Signature(signedData, signature);
  }
}
