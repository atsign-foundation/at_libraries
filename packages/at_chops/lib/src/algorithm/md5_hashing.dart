import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class MD5Hash implements AtHashingAlgorithm {
  @override
  String checkSum(Uint8List data) {
    return md5.convert(data).toString();
  }
}
