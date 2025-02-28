import 'dart:typed_data';

import 'package:at_chops/src/key/symmetric_key.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

/// Represents an AES key for symmetric encryption.
class AtAESKey extends SymmetricKey {
  @override
  final Uint8List raw;

  @override
  String get key => base64Encode(raw);

  AtAESKey(String base64) : raw = base64Decode(base64);
  AtAESKey.raw(this.raw);

  /// Generates an AES key for symmetric encryption with a given length.
  /// Key is created with a list of [length] with non negative values randomly generated from >=0 and < 256 and converted to base64 string
  static AtAESKey generate(int length) {
    var aesKey = AES(Key.fromSecureRandom(length));
    return AtAESKey(aesKey.key.base64);
  }

  /// Returns the key length in bytes.
  /// e.g for 128 bit key length will be 16
  /// for 192 bit key length will be 24
  /// for 256 bit key length will be 32
  int getLength() {
    return raw.length;
  }

  @override
  String toString() {
    return key;
  }
}
