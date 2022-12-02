import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/metadata/signing_result.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for encryption and decryption', () {
    test('Test rsa encryption/decryption string', () {
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final data = 'Hello World';
      final encryptionResult =
          atChops.encryptString(data, EncryptionKeyType.rsa2048);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.rsa2048);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'DefaultEncryptionAlgo');
      final decryptionResult = atChops.decryptString(
          encryptionResult.result, EncryptionKeyType.rsa2048);
      expect(decryptionResult.atEncryptionMetaData, isNotNull);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.rsa2048);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'DefaultEncryptionAlgo');
      expect(decryptionResult.result, data);
    });
    test('Test symmetric encrypt/decrypt bytes with initialisation vector', () {
      String data = 'Hello World';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptBytes(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(utf8.decode(decryptionResult.result), data);
    });
    test('Test symmetric encrypt/decrypt bytes with emoji char', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptBytes(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(utf8.decode(decryptionResult.result), data);
    });

    test('Test symmetric encrypt/decrypt bytes with special chars', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult = atChops.encryptBytes(
          utf8.encode(data) as Uint8List, EncryptionKeyType.aes256,
          iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptBytes(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(utf8.decode(decryptionResult.result), data);
    });
    test('Test symmetric encrypt/decrypt string with initialisation vector',
        () {
      String data = 'Hello World';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptString(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(decryptionResult.result, data);
    });
    test('Test symmetric encrypt/decrypt string with special chars', () {
      String data = 'Hello``*+%';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptString(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(decryptionResult.result, data);
    });
    test('Test symmetric encrypt/decrypt string with emoji', () {
      String data = 'Hello World🛠';
      final aesKey = AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
      final atChopsKeys = AtChopsKeys.createSymmetric(aesKey);
      final atChops = AtChopsImpl(atChopsKeys);
      final iv = AtChopsUtil.generateIV(16);
      final encryptionResult =
          atChops.encryptString(data, EncryptionKeyType.aes256, iv: iv);
      expect(encryptionResult.atEncryptionMetaData, isNotNull);
      expect(encryptionResult.result, isNotEmpty);
      expect(encryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(encryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(encryptionResult.atEncryptionMetaData.iv, iv);
      final decryptionResult = atChops.decryptString(
          encryptionResult.result, EncryptionKeyType.aes256,
          iv: iv);
      expect(decryptionResult.result, isNotEmpty);
      expect(decryptionResult.atEncryptionMetaData.encryptionKeyType,
          EncryptionKeyType.aes256);
      expect(decryptionResult.atEncryptionMetaData.atEncryptionAlgorithm,
          'AESEncryptionAlgo');
      expect(decryptionResult.atEncryptionMetaData.iv, iv);
      expect(decryptionResult.result, data);
    });
  });
  group('A group of tests for data signing and verification', () {
    test('Test pkam signing and verification', () {
      String data = 'Hello World';
      final atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final atChopsKeys = AtChopsKeys.create(null, atPkamKeyPair);
      final atChops = AtChopsImpl(atChopsKeys);
      final signingResult = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.pkamSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.pkamSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'PkamSigningAlgo');
      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          SigningKeyType.pkamSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.pkamSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'PkamSigningAlgo');
      expect(verificationResult.result, true);
    });
    test('Test data signing and verification - emoji char', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signingResult = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      expect(verificationResult.result, true);
    });

    test('Test data signing and verification - special char', () {
      String data = 'Hello\' World!*``';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signingResult = atChops.signBytes(
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      expect(verificationResult.result, true);
    });

    test('Test data signing and verification - string data type', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final signingResult =
          atChops.signString(data, SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.string);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      final verificationResult = atChops.verifySignatureString(
          data, signingResult.result, SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(signingResult.atSigningMetaData.signingKeyType,
          SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData.atSigningAlgorithm,
          'DefaultSigningAlgo');
      expect(verificationResult.result, true);
    });
  });
}
