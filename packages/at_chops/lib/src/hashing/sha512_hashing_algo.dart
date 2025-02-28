import 'package:at_chops/src/hashing/at_hashing_algorithm.dart';
import 'package:crypto/crypto.dart';

class SHA512HashingAlgo implements AtHashingAlgorithm<List<int>, String> {
  @override
  String hash(List<int> data, {covariant HashParams? hashParams}) {
    Digest digest = sha512.convert(data);
    return digest.toString();
  }
}
