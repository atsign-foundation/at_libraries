import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for default signing and verification', () {
    test(
        'Test default signing and verification using generated rsa 2048 key pair, default signing and hashing algo',
        () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = defaultSigningAlgo.sign(dataInBytes);
      var verifyResult =
          defaultSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test(
        'Test default signing and verification using generated rsa 4096 key pair, default signing and hashing algo',
        () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair(keySize: 4096);
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa4096, HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = defaultSigningAlgo.sign(dataInBytes);
      var verifyResult =
          defaultSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test('Test default signing and verification - set sha256 hashing algo', () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = defaultSigningAlgo.sign(dataInBytes);
      var verifyResult =
          defaultSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test('Test default signing and verification - set sha512 hashing algo', () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha512);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = defaultSigningAlgo.sign(dataInBytes);
      var verifyResult =
          defaultSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test(
        'Test default signing and verification - set md5 hashing algo - not supported',
        () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa2048, HashingAlgoType.md5);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      expect(
          () => defaultSigningAlgo.sign(dataInBytes),
          throwsA(predicate((e) =>
              e is AtException &&
              e.toString().contains(
                  'Hashing algo HashingAlgoType.md5 is invalid/not supported'))));
    });
    test('Test default signing - key pair not set', () {
      final defaultSigningAlgo = DefaultSigningAlgo(
          null, SigningAlgoType.rsa2048, HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      expect(
          () => defaultSigningAlgo.sign(dataInBytes),
          throwsA(predicate((e) =>
              e is AtException &&
              e.toString().contains(
                  'encryption key pair not set for default signing algo'))));
    });
    test('Test default verification - passing public key', () {
      var keyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      final defaultSigningAlgo = DefaultSigningAlgo(
          keyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = defaultSigningAlgo.sign(dataInBytes);
      final publicKeyString = keyPair.atPublicKey.publicKey;
      var verifyResult = defaultSigningAlgo
          .verify(dataInBytes, signatureInBytes, publicKey: publicKeyString);
      expect(verifyResult, true);
    });
  });
}
