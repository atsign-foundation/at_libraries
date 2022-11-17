import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:crypton/crypton.dart';

class RSAEncryptionAlgo implements AtEncryptionAlgorithm {
  final RSAKeypair _rsaKeypair;
  RSAEncryptionAlgo(this._rsaKeypair);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    return _rsaKeypair.publicKey.encryptData(plainData);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    return _rsaKeypair.privateKey.decryptData(encryptedData);
  }
}
