import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';

abstract class AtSymmetricKey extends AtEncryptionKey {
  Uint8List encrypt(Uint8List data, {InitialisationVector? iv});

  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv});
}
