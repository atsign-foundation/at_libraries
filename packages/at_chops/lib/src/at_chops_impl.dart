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

  /// Decode the encrypted string to base64.
  /// Decode the encrypted byte to utf8 to support emoji chars.
  @override
  String decryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    final decryptedBytes =
        decryptBytes(base64Decode(data), encryptionAlgorithm, iv: iv);
    return utf8.decode(decryptedBytes);
  }

  @override
  Uint8List encryptBytes(
      Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    return encryptionAlgorithm.encrypt(data, iv: iv);
  }

  /// Encode the input string to utf8 to support emoji chars.
  /// Encode the encrypted bytes to base64.
  @override
  String encryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm,
      {InitialisationVector? iv}) {
    final utfEncodedData = utf8.encode(data);
    final encryptedBytes = encryptBytes(
        Uint8List.fromList(utfEncodedData), encryptionAlgorithm,
        iv: iv);
    return base64.encode(encryptedBytes);
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
