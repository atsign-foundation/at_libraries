import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:encrypt/encrypt.dart';

class DefaultEncryptionAlgo implements AtAlgorithm {
  late AtEncryptionKeyPair _atEncryptionKeyPair;
  DefaultEncryptionAlgo(this._atEncryptionKeyPair);

  //# TODO implement IV
  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    var aesEncrypter = Encrypter(AES(
        Key.fromBase64(_atEncryptionKeyPair.atEncryptionPublicKey.publicKey)));
    return aesEncrypter.encryptBytes(plainData, iv: iv?.iv).bytes;
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    var aesKey = AES(
        Key.fromBase64(_atEncryptionKeyPair.atEncryptionPublicKey.publicKey));
    var decrypter = Encrypter(aesKey);
    return decrypter.decryptBytes(Encrypted(encryptedData as Uint8List),
        iv: iv?.iv) as Uint8List;
  }
}
