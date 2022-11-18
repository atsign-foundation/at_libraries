import 'dart:typed_data';

import 'package:at_chops/src/key/impl/v2/at_key_pair.dart';

class AtPkamKeyPair {
  final AtKeyPair _atKeyPair;
  AtPkamKeyPair(this._atKeyPair);

  Uint8List sign(Uint8List message) {
    return _atKeyPair.sign(message);
  }

  bool verify(Uint8List message, Uint8List signature) {
    return _atKeyPair.verify(message, signature);
  }
}