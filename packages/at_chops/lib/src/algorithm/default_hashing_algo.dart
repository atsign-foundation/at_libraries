import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:crypto/crypto.dart';

class DefaultHash implements AtHashingAlgorithm {
  @override
  String hash(List<int> data) {
    return md5.convert(data).toString();
  }
}
