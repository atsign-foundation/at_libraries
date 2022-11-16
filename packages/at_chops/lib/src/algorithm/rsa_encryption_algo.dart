import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:crypton/crypton.dart';

class RSAEncryptionAlgo implements AtEncryptionAlgorithm {
  late AtEncryptionKeyPair _atEncryptionKeyPair;
  RSAEncryptionAlgo(this._atEncryptionKeyPair);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    final publicKey =
        RSAPublicKey.fromString(_atEncryptionKeyPair.publicKeyString);
    return publicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    final privateKey =
        RSAPrivateKey.fromString(_atEncryptionKeyPair.privateKeyString);
    return privateKey.decryptData(encryptedData);
  }
}
