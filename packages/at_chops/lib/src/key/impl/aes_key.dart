import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/key/at_encryption_key.dart';
import 'package:encrypt/encrypt.dart';

/// Represents an AES key for symmetric encryption.
class AESKey {
  late String _aesKey;
  AESKey(this._aesKey);
  String get key => _aesKey;

  /// Generates an AES key for symmetric encryption with a given length.
  /// Key is created with a list of [length] with non negative values randomly generated from >=0 and < 256 and converted to base64 string
  AESKey.generate(int length) {
    var aesKey = AES(Key.fromSecureRandom(length));
    _aesKey = aesKey.key.base64;
  }

  @override
  String toString() {
    return _aesKey;
  }
}
