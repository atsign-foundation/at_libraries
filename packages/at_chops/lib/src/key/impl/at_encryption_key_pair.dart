import 'dart:typed_data';

import 'package:at_chops/src/key/at_key_pair.dart';

class AtEncryptionKeyPair {
  final AtKeyPair _atKeyPair;
  AtEncryptionKeyPair(this._atKeyPair);

  Uint8List decrypt(Uint8List encryptedData) {
    return _atKeyPair.decrypt(encryptedData);
  }

  Uint8List encrypt(Uint8List data) {
    return _atKeyPair.encrypt(data);
  }
}
