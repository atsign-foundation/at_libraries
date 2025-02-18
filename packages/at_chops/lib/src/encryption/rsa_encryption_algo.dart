import 'dart:typed_data';

import 'package:at_chops/src/encryption/at_encryption_algorithm.dart';
import 'package:at_chops/src/key/at_rsa_key_pair.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypton/crypton.dart';

class RsaEncryptionAlgo
    implements AsymmetricEncryptionAlgorithm<AtRSAPublicKey, AtRSAPrivateKey> {
  AtRSAKeyPair? _encryptionKeypair;
  RsaEncryptionAlgo.fromKeyPair(this._encryptionKeypair);
  RsaEncryptionAlgo();
  @override
  Uint8List encrypt(Uint8List plainData) {
    if ((_encryptionKeypair == null ||
            _encryptionKeypair!.atPublicKey.publicKey.isEmpty) &&
        (atPublicKey == null || atPublicKey!.publicKey.isEmpty)) {
      throw AtEncryptionException('EncryptionKeypair/public key not set');
    }
    var publicKeyString = atPublicKey?.publicKey;
    publicKeyString ??= _encryptionKeypair!.atPublicKey.publicKey;
    final rsaPublicKey = RSAPublicKey.fromString(publicKeyString);
    return rsaPublicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData) {
    if ((_encryptionKeypair == null ||
            _encryptionKeypair!.atPrivateKey.privateKey.isEmpty) &&
        (atPrivateKey == null || atPrivateKey!.privateKey.isEmpty)) {
      throw AtDecryptionException('EncryptionKeypair/public key not set');
    }
    var privateKeyString = atPrivateKey?.privateKey;
    privateKeyString ??= _encryptionKeypair!.atPrivateKey.privateKey;
    final rsaPrivateKey = RSAPrivateKey.fromString(privateKeyString);
    return rsaPrivateKey.decryptData(encryptedData);
  }

  @override
  AtRSAPrivateKey? atPrivateKey;

  @override
  AtRSAPublicKey? atPublicKey;
}
