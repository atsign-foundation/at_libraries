import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

abstract class AtChops {
  List<int> encrypt(Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm);
  String encryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm);
  List<int> decrypt(Uint8List data, AtEncryptionAlgorithm encryptionAlgorithm);
  String decryptString(String data, AtEncryptionAlgorithm encryptionAlgorithm);
  Uint8List sign(Uint8List data, AtSigningAlgorithm signingAlgorithm);
  bool verify(Uint8List signedData, Uint8List signature,
      AtSigningAlgorithm signingAlgorithm);
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm);
}
