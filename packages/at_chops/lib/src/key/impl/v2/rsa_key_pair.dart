import 'dart:typed_data';

import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:crypton/crypton.dart';

class AtRSAKeyPair extends AtKeyPair {
  final AtRSAPublicKey _atRSAPublicKey;

  AtRSAPublicKey get atRSAPublicKey => _atRSAPublicKey;
  final AtRSAPrivateKey _atRSAPrivateKey;

  AtRSAPrivateKey get atRSAPrivateKey => _atRSAPrivateKey;
  AtRSAKeyPair(this._atRSAPrivateKey, this._atRSAPublicKey)
      : super(_atRSAPrivateKey, _atRSAPublicKey);

  /// Generates RSA keypair with default size 2048 bits
  static AtRSAKeyPair generate({int? keySize}) {
    final rsaKeypair = RSAKeypair.fromRandom();
    return AtRSAKeyPair(AtRSAPrivateKey(rsaKeypair.privateKey),
        AtRSAPublicKey(rsaKeypair.publicKey));
  }
}

class AtRSAPublicKey implements AtPublicKey {
  late RSAPublicKey _rsaPublicKey;
  AtRSAPublicKey(this._rsaPublicKey);
  @override
  bool verifySHA256Signature(Uint8List message, Uint8List signature) {
    return _rsaPublicKey.verifySHA256Signature(message, signature);
  }

  @override
  Uint8List encrypt(Uint8List data) {
    return _rsaPublicKey.encryptData(data);
  }
}

class AtRSAPrivateKey implements AtPrivateKey {
  late RSAPrivateKey _rsaPrivateKey;
  AtRSAPrivateKey(this._rsaPrivateKey);
  @override
  Uint8List createSHA256Signature(Uint8List message) {
    return _rsaPrivateKey.createSHA256Signature(message);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData) {
    return _rsaPrivateKey.decryptData(encryptedData);
  }
}