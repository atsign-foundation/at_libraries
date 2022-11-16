import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:encrypt/encrypt.dart';

class AtChopsUtil {
  /// Generates a random initialisation vector from a given length
  /// Length must be 0 to 16
  /// #TODO explain about implications of changing length
  static InitialisationVector generateIV(int length) {
    final iv = IV.fromSecureRandom(length);
    return InitialisationVector(iv.bytes);
  }

}
