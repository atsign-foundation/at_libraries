import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class AtEncryptor {
  final AtAlgorithm _atAlgorithm;
  AtEncryptor(this._atAlgorithm);

  List<int> encrypt(Uint8List data) {
    return _atAlgorithm.encrypt(data);
  }

  Uint8List decrypt(Uint8List encryptedData) {
    return _atAlgorithm.decrypt(encryptedData);
  }
}
