import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:encrypt/encrypt.dart';

class AESEncryptionAlgo implements AtEncryptionAlgorithm {
  late AtEncryptionKeyPair _atEncryptionKeyPair;
  AESEncryptionAlgo(this._atEncryptionKeyPair);

  @override
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv}) {
    //#TODO implement
    return Uint8List.fromList([]);
  }

  @override
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv}) {
    //#TODO implement
    return Uint8List.fromList([]);
  }
}
