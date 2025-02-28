import 'dart:typed_data';

/// Represent a key for symmetric key encryption/decryption
abstract class SymmetricKey {
  String get key;
  Uint8List get raw;

  @override
  String toString() => key;
}
