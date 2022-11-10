import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';

import '../at_chops.dart';

class AtChopsImpl implements AtChops {
  @override
  Uint8List decryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    return encryptionAlgorithm.decrypt(data, iv: iv);
  }

  @override
  String decryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    return utf8.decode(decryptBytes(
        utf8.encode(data) as Uint8List, encryptionAlgorithm,
        iv: iv));
  }

  @override
  Uint8List encryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    return encryptionAlgorithm.encrypt(data, iv: iv);
  }

  @override
  String encryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    return utf8.decode(encryptBytes(
        utf8.encode(data) as Uint8List, encryptionAlgorithm,
        iv: iv));
  }

  @override
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm) {
    return hashingAlgorithm.hash(signedData);
  }

  @override
  Uint8List sign(Uint8List data, AtSigningAlgorithm signingAlgorithm) {
    return signingAlgorithm.sign(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature,
      AtSigningAlgorithm signingAlgorithm) {
    return signingAlgorithm.verify(signedData, signature);
  }
}
