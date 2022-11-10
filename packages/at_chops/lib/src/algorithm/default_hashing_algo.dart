import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import 'package:at_chops/src/algorithm/at_algorithm.dart';

class DefaultHash implements AtHashingAlgorithm {
  @override
  String hash(List<int> data) {
    return md5.convert(data).toString();
  }
}
