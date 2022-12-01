import 'dart:convert';
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
          atChops.encryptString(data, EncryptionKeyType.rsa2048);
      final decryptedString =
          atChops.decryptString(encryptedString, EncryptionKeyType.rsa2048);
      expect(decryptedString, data);
    });
    test('Test symmetric encrypt/decrypt bytes with initialisation vector', () {
      String data = 'Hello World';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedBytes = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      final decryptedBytes = atChops
          .decryptBytes(encryptedBytes, EncryptionKeyType.aes256, iv: iv);
      expect(utf8.decode(decryptedBytes), data);
    });
    test('Test symmetric encrypt/decrypt bytes with emoji char', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedBytes = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      final decryptedBytes = atChops
          .decryptBytes(encryptedBytes, EncryptionKeyType.aes256, iv: iv);
      expect(utf8.decode(decryptedBytes), data);
    });

    test('Test symmetric encrypt/decrypt bytes with special chars', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedBytes = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      final decryptedBytes = atChops
          .decryptBytes(encryptedBytes, EncryptionKeyType.aes256, iv: iv);
      expect(utf8.decode(decryptedBytes), data);
    });
    test('Test symmetric encrypt/decrypt string with initialisation vector',
        () {
      String data = 'Hello World';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedString =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      final decryptedString = atChops
          .decryptString(encryptedString, EncryptionKeyType.aes256, iv: iv);
      expect(decryptedString, data);
    });
    test('Test symmetric encrypt/decrypt string with special chars', () {
      String data = 'Hello``*+%';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedString =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      final decryptedString = atChops
          .decryptString(encryptedString, EncryptionKeyType.aes256, iv: iv);
      expect(decryptedString, data);
    });
    test('Test symmetric encrypt/decrypt string with emoji', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptedString =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      final decryptedString = atChops
          .decryptString(encryptedString, EncryptionKeyType.aes256, iv: iv);
      expect(decryptedString, data);
    });
  });
  group('A group of tests for data signing and verification', () {
    test('Test pkam signing and verification', () {
      String data = 'Hello World';
      final atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final atChopsKeys = AtChopsKeys.create(null, atPkamKeyPair);
      final atChops = AtChopsImpl(atChopsKeys);
      final signature = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.pkamSha256);
      final result = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signature,
          SigningKeyType.pkamSha256);
      expect(result, true);
    });
    test('Test data signing and verification - emoji char', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signature = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      final result = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signature,
          SigningKeyType.signingSha256);
      expect(result, true);
    });

    test('Test data signing and verification - special char', () {
      String data = 'Hello\' World!*``';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signature = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      final result = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signature,
          SigningKeyType.signingSha256);
      expect(result, true);
    });

    test('Test data signing and verification - string data type', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signature = atChops.signString(data, SigningKeyType.signingSha256);
      final result = atChops.verifySignatureString(
          data, signature, SigningKeyType.signingSha256);
      expect(result, true);
    });
  });
}
