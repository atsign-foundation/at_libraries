import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:encrypt/encrypt.dart';

/// Represents an AES key for symmetric encryption.
class AESKey extends SymmetricKey {
  final String _aesKey;
  @override
  String get key => _aesKey;
  AESKey(this._aesKey) : super(_aesKey);

  /// Generates an AES key for symmetric encryption with a given length.
  /// Key is created with a list of [length] with non negative values randomly generated from >=0 and < 256 and converted to base64 string
  static AESKey generate(int length) {
    var aesKey = AES(Key.fromSecureRandom(length));
    return AESKey(aesKey.key.base64);
  }

  @override
  String toString() {
    return _aesKey;
  }
}
