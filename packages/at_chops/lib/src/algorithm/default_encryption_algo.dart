import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

class DefaultEncryptionAlgo implements ASymmetricEncryptionAlgorithm {
  AtEncryptionKeyPair? _encryptionKeypair;
  DefaultEncryptionAlgo.fromKeyPair(this._encryptionKeypair);
  DefaultEncryptionAlgo();
  @override
  Uint8List encrypt(Uint8List plainData, {AtPublicKey? atPublicKey}) {
    if ((_encryptionKeypair == null ||
            _encryptionKeypair!.atPublicKey.publicKey.isEmpty) &&
        (atPublicKey == null || atPublicKey.publicKey.isEmpty)) {
      throw AtEncryptionException('EncryptionKeypair/public key not set');
    }
    var publicKeyString = atPublicKey?.publicKey;
    publicKeyString ??= _encryptionKeypair!.atPublicKey.publicKey;
    final rsaPublicKey = RSAPublicKey.fromString(publicKeyString);
    return rsaPublicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {AtPrivateKey? atPrivateKey}) {
    if ((_encryptionKeypair == null ||
            _encryptionKeypair!.atPrivateKey.privateKey.isEmpty) &&
        (atPrivateKey == null || atPrivateKey.privateKey.isEmpty)) {
      throw AtDecryptionException('EncryptionKeypair/public key not set');
    }
    var privateKeyString = atPrivateKey?.privateKey;
    privateKeyString ??= _encryptionKeypair!.atPrivateKey.privateKey;
    final rsaPrivateKey = RSAPrivateKey.fromString(privateKeyString);
    return rsaPrivateKey.decryptData(encryptedData);
  }
}
