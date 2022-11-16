import 'package:at_chops/src/key/aes_key.dart';
import 'package:encrypt/encrypt.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for AES Key generation', () {
    test('Test generate AESKey - 128 bit', () {
      final aesKey = AESKey.create(16);
      expect(Key.fromBase64(aesKey.key).length, 16);
    });
    test('Test generate AESKey - 128 bit random generation', () {
      final aesKey_1 = AESKey.create(16);
      final aesKey_2 = AESKey.create(16);
      expect(aesKey_1, isNot(aesKey_2));
    });
    test('Test generate AESKey - 256 bit', () {
      final aesKey = AESKey.create(32);
      expect(Key.fromBase64(aesKey.key).length, 32);
    });
    test('Test generate AESKey - 256 bit random generation', () {
      final aesKey_1 = AESKey.create(32);
      final aesKey_2 = AESKey.create(32);
      expect(aesKey_1, isNot(aesKey_2));
    });
  });
}
