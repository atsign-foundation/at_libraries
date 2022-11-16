import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:crypton/crypton.dart';

//#TODO delete algo classes if alternate design is approved
class RSAEncryptionAlgo implements AtEncryptionAlgorithm {
  late AtEncryptionKeyPair _atEncryptionKeyPair;
  RSAEncryptionAlgo(this._atEncryptionKeyPair);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    final publicKey =
        RSAPublicKey.fromString('dummy');
    return publicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    final privateKey =
        RSAPrivateKey.fromString('dummy');
    return privateKey.decryptData(encryptedData);
  }
}
