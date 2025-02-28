import 'package:at_chops/src/hashing/at_hashing_algorithm.dart';
import 'package:crypto/crypto.dart';

class Md5HashingAlgo implements AtHashingAlgorithm<List<int>, String> {
  @override
  String hash(List<int> data, {HashParams? hashParams}) {
    return md5.convert(data).toString();
  }
}
