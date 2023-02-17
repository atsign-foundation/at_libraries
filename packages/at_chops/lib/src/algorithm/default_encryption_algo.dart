import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

class DefaultEncryptionAlgo implements AtEncryptionAlgorithm {
  final AtEncryptionKeyPair _encryptionKeypair;
  final EncryptionKeyType _encryptionKeyType;
  DefaultEncryptionAlgo(this._encryptionKeypair, this._encryptionKeyType);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    if (_encryptionKeypair.atPublicKey.publicKey.isEmpty) {
      throw AtEncryptionException('encryption public key is empty');
    }
    final rsaPublicKey =
        RSAPublicKey.fromString(_encryptionKeypair.atPublicKey.publicKey);
    return rsaPublicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    if (_encryptionKeypair.atPrivateKey.privateKey.isEmpty) {
      throw AtDecryptionException('decryption private key is empty');
    }
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeypair.atPrivateKey.privateKey);
    return rsaPrivateKey.decryptData(encryptedData);
  }
}
