import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:at_chops/src/key/signing_key.dart';

abstract class AtEncryptionAlgorithm {
  AtEncryptionAlgorithm(AtEncryptionKey atEncryptionKey);
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv});
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv});
}

abstract class AtSigningAlgorithm {
  AtSigningAlgorithm(AtSigningKeyPair keyPair);
  Uint8List sign(Uint8List data);
  bool verify(Uint8List signedData, Uint8List signature);
}

abstract class AtHashingAlgorithm {
  String hash(Uint8List data);
}
