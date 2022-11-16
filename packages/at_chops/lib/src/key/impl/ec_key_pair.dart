import 'dart:typed_data';

import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:crypton/crypton.dart';

import '../at_public_key.dart';

class AtECKeyPair extends AtKeyPair {
  final AtECPublicKey _atECPublicKey;

  AtECKeyPair(this._atECPrivateKey, this._atECPublicKey)
      : super(_atECPrivateKey, _atECPublicKey);

  AtECPublicKey get atECPublicKey => _atECPublicKey;
  final AtECPrivateKey _atECPrivateKey;

  AtECPrivateKey get atECPrivateKey => _atECPrivateKey;

  /// Generates EC keypair
  static AtECKeyPair generate() {
    final ecKeypair = ECKeypair.fromRandom();
    return AtECKeyPair(AtECPrivateKey(ecKeypair.privateKey),
        AtECPublicKey(ecKeypair.publicKey));
  }
}

class AtECPublicKey implements AtPublicKey {
  final ECPublicKey _ecPublicKey;
  AtECPublicKey(this._ecPublicKey);
  @override
  bool verifySHA256Signature(Uint8List message, Uint8List signature) {
    return _ecPublicKey.verifySHA256Signature(message, signature);
  }

  @override
  Uint8List encrypt(Uint8List data) {
    throw UnimplementedError();
  }
}

class AtECPrivateKey implements AtPrivateKey {
  final ECPrivateKey _ecPrivateKey;
  AtECPrivateKey(this._ecPrivateKey);
  @override
  Uint8List createSHA256Signature(Uint8List message) {
    return _ecPrivateKey.createSHA256Signature(message);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData) {
    throw UnimplementedError();
  }
}
