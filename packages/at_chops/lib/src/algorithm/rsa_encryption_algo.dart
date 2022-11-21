import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:crypton/crypton.dart';

class RSAEncryptionAlgo implements AtEncryptionAlgorithm {
  final AtEncryptionKeyPair _encryptionKeypair;
  final EncryptionKeyType _encryptionKeyType;
  RSAEncryptionAlgo(this._encryptionKeypair, this._encryptionKeyType);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    final rsaPublicKey =
        RSAPublicKey.fromString(_encryptionKeypair.atPublicKey.publicKey);
    return rsaPublicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeypair.atPrivateKey.privateKey);
    return rsaPrivateKey.decryptData(encryptedData);
  }
}
