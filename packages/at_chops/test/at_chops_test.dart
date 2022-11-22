import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for encryption and decryption', () {
    test('Test rsa encryption/decryption string', () {
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final data = 'Hello World';
      final encryptedString =
          atChops.encryptString(data, EncryptionKeyType.rsa_2048);
      final decryptedString =
          atChops.decryptString(encryptedString, EncryptionKeyType.rsa_2048);
      expect(decryptedString, data);
    });
    //   test('Test symmetric encrypt/decrypt bytes with initialisation vector', () {
    //     String data = 'Hello World';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedBytes =
    //         atChops.encryptBytes(utf8.encode(data) as Uint8List, algo, iv: iv);
    //     final decryptedBytes = atChops.decryptBytes(encryptedBytes, algo, iv: iv);
    //     expect(utf8.decode(decryptedBytes), data);
    //   });
    //   test('Test symmetric encrypt/decrypt bytes with emoji char', () {
    //     String data = 'Hello World🛠';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedBytes =
    //         atChops.encryptBytes(utf8.encode(data) as Uint8List, algo, iv: iv);
    //     final decryptedBytes = atChops.decryptBytes(encryptedBytes, algo, iv: iv);
    //     expect(utf8.decode(decryptedBytes), data);
    //   });
    //
    //   test('Test symmetric encrypt/decrypt bytes with special chars', () {
    //     String data = 'Hello World🛠';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedBytes =
    //         atChops.encryptBytes(utf8.encode(data) as Uint8List, algo, iv: iv);
    //     final decryptedBytes = atChops.decryptBytes(encryptedBytes, algo, iv: iv);
    //     expect(utf8.decode(decryptedBytes), data);
    //   });
    //   test('Test symmetric encrypt/decrypt string with initialisation vector',
    //       () {
    //     String data = 'Hello World';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedString = atChops.encryptString(data, algo, iv: iv);
    //     final decryptedString =
    //         atChops.decryptString(encryptedString, algo, iv: iv);
    //     expect(decryptedString, data);
    //   });
    //   test('Test symmetric encrypt/decrypt string with special chars', () {
    //     String data = 'Hello``*+%';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedString = atChops.encryptString(data, algo, iv: iv);
    //     final decryptedString =
    //         atChops.decryptString(encryptedString, algo, iv: iv);
    //     expect(decryptedString, data);
    //   });
    //   test('Test symmetric encrypt/decrypt string with emoji', () {
    //     String data = 'Hello World🛠';
    //     final atChops = AtChopsImpl();
    //     AESKey aesKey = AESKey.generate(32);
    //     final iv = AtChopsUtil.generateIV(16);
    //     final algo = DefaultEncryptionAlgo(aesKey);
    //     final encryptedString = atChops.encryptString(data, algo, iv: iv);
    //     final decryptedString =
    //         atChops.decryptString(encryptedString, algo, iv: iv);
    //     expect(decryptedString, data);
    //   });
  });
  group('A group of tests for data signing and verification', () {
    test('Test pkam signing and verification', () {
      String data = 'Hello World';
      final atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final atChopsKeys = AtChopsKeys.create(null, atPkamKeyPair);
      final atChops = AtChopsImpl(atChopsKeys);
      final signature = atChops.sign(Uint8List.fromList(data.codeUnits), SigningKeyType.pkam_sha_256);
      final result =
          atChops.verify(Uint8List.fromList(data.codeUnits), signature, SigningKeyType.pkam_sha_256);
      expect(result, true);
    });
    // test('Test data signing and verification - emoji char', () {
    //   String data = 'Hello World🛠';
    //   final atChops = AtChopsImpl();
    //   final atSigningKeyPair = AtChopsUtil.generateRSAKeyPair();
    //   final algo = DefaultSigningAlgo(atSigningKeyPair);
    //   final signature = atChops.sign(Uint8List.fromList(data.codeUnits), algo);
    //   final result =
    //       atChops.verify(Uint8List.fromList(data.codeUnits), signature, algo);
    //   expect(result, true);
    // });
    // test('Test data signing and verification - special char', () {
    //   String data = 'Hello\' World!*``';
    //   final atChops = AtChopsImpl();
    //   final atSigningKeyPair = AtChopsUtil.generateRSAKeyPair();
    //   final algo = DefaultSigningAlgo(atSigningKeyPair);
    //   final signature = atChops.sign(Uint8List.fromList(data.codeUnits), algo);
    //   final result =
    //       atChops.verify(Uint8List.fromList(data.codeUnits), signature, algo);
    //   expect(result, true);
    // });
  });
}
