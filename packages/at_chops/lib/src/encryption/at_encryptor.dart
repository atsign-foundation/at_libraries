import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class AtEncryptor {
  final AtEncryptionAlgorithm _atAlgorithm;
  AtEncryptor(this._atAlgorithm);

  Uint8List encrypt(Uint8List data) {
    return _atAlgorithm.encrypt(data);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    return _atAlgorithm.decrypt(encryptedData);
  }
}
