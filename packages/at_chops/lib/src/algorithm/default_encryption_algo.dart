import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

class DefaultEncryptionAlgo implements ASymmetricEncryptionAlgorithm {
  final AtEncryptionKeyPair _encryptionKeypair;
  DefaultEncryptionAlgo(this._encryptionKeypair);

  @override
  Uint8List encrypt(Uint8List plainData, {AtPublicKey? atPublicKey}) {
    //#TODO encrypt using atPublicKey if passed
    if (_encryptionKeypair.atPublicKey.publicKey.isEmpty) {
      throw AtEncryptionException('encryption public key is empty');
    }
    final rsaPublicKey =
        RSAPublicKey.fromString(_encryptionKeypair.atPublicKey.publicKey);
    return rsaPublicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {AtPrivateKey? atPrivateKey}) {
    //#TODO decrypt using atPrivateKey if passed
    if (_encryptionKeypair.atPrivateKey.privateKey.isEmpty) {
      throw AtDecryptionException('decryption private key is empty');
    }
    final rsaPrivateKey =
        RSAPrivateKey.fromString(_encryptionKeypair.atPrivateKey.privateKey);
    return rsaPrivateKey.decryptData(encryptedData);
  }
}
