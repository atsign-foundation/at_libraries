import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/aes_key.dart';
import 'package:encrypt/encrypt.dart';

class DefaultEncryptionAlgo implements AtEncryptionAlgorithm {
  late AESKey _aesKey;
  DefaultEncryptionAlgo(this._aesKey);

  //# TODO implement IV
  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    var aesEncrypter = Encrypter(AES(Key.fromBase64(_aesKey.toString())));
    return aesEncrypter.encryptBytes(plainData, iv: iv?.iv).bytes;
  }

  //# TODO implement IV
  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    var aesKey = AES(Key.fromBase64(_aesKey.toString()));
    var decrypter = Encrypter(aesKey);
    return decrypter.decryptBytes(Encrypted(encryptedData), iv: iv?.iv)
        as Uint8List;
  }
}
