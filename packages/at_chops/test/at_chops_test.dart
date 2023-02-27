import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';
import 'package:test/test.dart';

void main() {
  AtSignLogger.root_level = 'finest';
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
          // ignore: deprecated_member_use_from_same_package
          Uint8List.fromList(data.codeUnits), SigningKeyType.pkamSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          // ignore: deprecated_member_use_from_same_package
          SigningKeyType.pkamSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test('Test data signing and verification - emoji char', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      final signingResult = atChops.signBytes(
        // ignore: deprecated_member_use_from_same_package
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          // ignore: deprecated_member_use_from_same_package
          SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test('Test data signing and verification - special char', () {
      String data = 'Hello\' World!*``';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      final signingResult = atChops.signBytes(
        // ignore: deprecated_member_use_from_same_package
          Uint8List.fromList(data.codeUnits), SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      final verificationResult = atChops.verifySignatureBytes(
          Uint8List.fromList(data.codeUnits),
          signingResult.result,
          // ignore: deprecated_member_use_from_same_package
          SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test('Test data signing and verification - string data type', () {
      String data = 'Hello World🛠';
      final atEncryptionKeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      final signingResult =
      // ignore: deprecated_member_use_from_same_package
          atChops.signString(data, SigningKeyType.signingSha256);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result, isNotEmpty);
      expect(signingResult.atSigningResultType, AtSigningResultType.string);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      final verificationResult = atChops.verifySignatureString(
        // ignore: deprecated_member_use_from_same_package
          data, signingResult.result, SigningKeyType.signingSha256);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test('Test sign() and verify() with default algorithms', () {
      final data = 'testData';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      RSAPrivateKey rsaPrivateKey =
          RSAPrivateKey.fromString(encryptionKeypair.atPrivateKey.privateKey);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      final signingResult = atChops.sign(signingInput);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result,
          rsaPrivateKey.createSHA256Signature(utf8.encode(data) as Uint8List));
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);
      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test(
        'Test sign() and verify() with signingAlgo - rsa2048 and hashing algo - sha256',
        () {
      final data = 'randomText';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      RSAPrivateKey rsaPrivateKey =
          RSAPrivateKey.fromString(encryptionKeypair.atPrivateKey.privateKey);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgoType = SigningAlgoType.rsa2048;
      signingInput.hashingAlgoType = HashingAlgoType.sha256;
      AtSigningAlgorithm signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      signingInput.signingAlgorithm = signingAlgorithm;
      final signingResult = atChops.sign(signingInput);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result,
          rsaPrivateKey.createSHA256Signature(utf8.encode(data) as Uint8List));
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha256;
      AtSigningAlgorithm verifyAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);
      verificationInput.signingAlgorithm = verifyAlgorithm;
      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, true);
    });

    test(
        'Test sign() and verify() with signingAlgo - rsa2048 and hashing algo - sha512',
        () {
      final data = 'aBcDeFg';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);
      RSAPrivateKey rsaPrivateKey =
          RSAPrivateKey.fromString(encryptionKeypair.atPrivateKey.privateKey);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgoType = SigningAlgoType.rsa2048;
      signingInput.hashingAlgoType = HashingAlgoType.sha512;
      AtSigningAlgorithm signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      signingInput.signingAlgorithm = signingAlgorithm;
      final signingResult = atChops.sign(signingInput);
      expect(signingResult.atSigningMetaData, isNotNull);
      expect(signingResult.result,
          rsaPrivateKey.createSHA512Signature(utf8.encode(data) as Uint8List));
      expect(signingResult.atSigningResultType, AtSigningResultType.bytes);
      expect(signingResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(signingResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha512);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha512;
      AtSigningAlgorithm verifyAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);
      verificationInput.signingAlgorithm = verifyAlgorithm;
      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha512);
      expect(verificationResult.result, true);
    });

    test(
        'Negative test - verify() fails when verifying sha256 sign using sha512',
        () {
      final data = 'data is important';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgoType = SigningAlgoType.rsa2048;
      signingInput.hashingAlgoType = HashingAlgoType.sha256;
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      final signingResult = atChops.sign(signingInput);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha512;
      verificationInput.signingAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);

      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha512);
      expect(verificationResult.result, false);
    });

    test(
        'Negative test - verify() fails when verifying sha512 sign using sha256',
        () {
      final data = 'data atad';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgoType = SigningAlgoType.rsa2048;
      signingInput.hashingAlgoType = HashingAlgoType.sha512;
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      final signingResult = atChops.sign(signingInput);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha256;
      verificationInput.signingAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);

      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, false);
    });

    test('Negative test - verify() fails with sha256 as hashing algo', () {
      final data = 'random data string';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(
              data, 'dummysignature', encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha256;
      AtSigningAlgorithm verifyAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);
      verificationInput.signingAlgorithm = verifyAlgorithm;

      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, false);
    });

    test('Negative test - verify() fails with sha512 as hashing algo', () {
      final data = 'some other random data string';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final atChopsKeys = AtChopsKeys.create(encryptionKeypair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, 'newdummysignature',
              encryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgoType = SigningAlgoType.rsa2048;
      verificationInput.hashingAlgoType = HashingAlgoType.sha512;
      AtSigningAlgorithm verifyAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);
      verificationInput.signingAlgorithm = verifyAlgorithm;

      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha512);
      expect(verificationResult.result, false);
    });

    test('Negative test - verify() fails with incorrect publicKey', () {
      final data = 'data does not matter';
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();
      final anotherEncryptionKeypair =
          AtChopsUtil.generateAtEncryptionKeyPair();
      AtEncryptionKeyPair dummyKeyPair = AtEncryptionKeyPair.create(
          encryptionKeypair.atPrivateKey.privateKey, '');
      final atChopsKeys = AtChopsKeys.create(dummyKeyPair, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningInput signingInput = AtSigningInput(data);
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      final signingResult = atChops.sign(signingInput);

      AtSigningVerificationInput? verificationInput =
          AtSigningVerificationInput(data, signingResult.result,
              anotherEncryptionKeypair.atPublicKey.publicKey);
      verificationInput.signingAlgorithm = DefaultSigningAlgo(
          encryptionKeypair, verificationInput.hashingAlgoType);

      AtSigningResult verificationResult = atChops.verify(verificationInput);
      expect(verificationResult.atSigningMetaData, isNotNull);
      expect(verificationResult.atSigningResultType, AtSigningResultType.bool);
      expect(verificationResult.atSigningMetaData.signingAlgoType,
          SigningAlgoType.rsa2048);
      expect(verificationResult.atSigningMetaData.hashingAlgoType,
          HashingAlgoType.sha256);
      expect(verificationResult.result, false);
    });

    test('Negative test - sign() fails without encryptionKeypair', () {
      final atChopsKeys = AtChopsKeys.create(null, null);
      final atChops = AtChopsImpl(atChopsKeys);

      AtSigningInput signingInput = AtSigningInput('abcde');
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(null, signingInput.hashingAlgoType);
      try {
        atChops.sign(signingInput);
      } catch (e, _) {
        assert(e is AtException);
        expect(e.toString(),
            'Exception: encryption key pair not set for default signing algo');
      }
    });

    test('Negative test - sign() with incorrect DataType', () {
      final atChopsKeys = AtChopsKeys.create(null, null);
      final atChops = AtChopsImpl(atChopsKeys);
      final encryptionKeypair = AtChopsUtil.generateAtEncryptionKeyPair();

      AtSigningInput signingInput = AtSigningInput(213456777);
      signingInput.signingAlgorithm =
          DefaultSigningAlgo(encryptionKeypair, signingInput.hashingAlgoType);
      try {
        atChops.sign(signingInput);
      } catch (e, _) {
        assert(e is AtException);
        expect(e.toString(), 'Exception: Unrecognized type of data: 213456777');
      }
    });
  });
}
