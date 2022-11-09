import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';

abstract class AtAlgorithm {
  Uint8List encrypt(Uint8List plainData, {InitialisationVector? iv});
  Uint8List decrypt(Uint8List encryptedData, {InitialisationVector? iv});
}

abstract class AtSigningAlgorithm {
  Uint8List sign(Uint8List data);
  bool verify(Uint8List signedData, Uint8List signature);
}
