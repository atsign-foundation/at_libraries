import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for pkam signing and verification', () {
    test(
        'Test pkam signing and verification using generated rsa 2048 key pair, default signing and hashing algo',
        () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = pkamSigningAlgo.sign(dataInBytes);
      var verifyResult = pkamSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test(
        'Test pkam signing and verification using generated rsa 4096 key pair, default signing and hashing algo',
        () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair(keySize: 4096);
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = pkamSigningAlgo.sign(dataInBytes);
      var verifyResult = pkamSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test('Test pkam signing and verification - set sha256 hashing algo', () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      pkamSigningAlgo.setHashingAlgoType(HashingAlgoType.sha256);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = pkamSigningAlgo.sign(dataInBytes);
      var verifyResult = pkamSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test('Test pkam signing and verification - set sha512 hashing algo', () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      pkamSigningAlgo.setHashingAlgoType(HashingAlgoType.sha512);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = pkamSigningAlgo.sign(dataInBytes);
      var verifyResult = pkamSigningAlgo.verify(dataInBytes, signatureInBytes);
      expect(verifyResult, true);
    });
    test(
        'Test pkam signing and verification - set md5 hashing algo - not supported',
        () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      pkamSigningAlgo.setHashingAlgoType(HashingAlgoType.md5);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      expect(
          () => pkamSigningAlgo.sign(dataInBytes),
          throwsA(predicate((e) =>
              e is AtException &&
              e.toString().contains(
                  'Hashing algo HashingAlgoType.md5 is invalid/not supported'))));
    });
    test('Test pkam signing - pkam key pair not set', () {
      final pkamSigningAlgo = PkamSigningAlgo(null);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      expect(
          () => pkamSigningAlgo.sign(dataInBytes),
          throwsA(predicate((e) =>
              e is AtException &&
              e
                  .toString()
                  .contains('pkam key pair is null. cannot sign data'))));
    });
    test('Test pkam verification - passing public key', () {
      var pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      final pkamSigningAlgo = PkamSigningAlgo(pkamKeyPair);
      pkamSigningAlgo.setHashingAlgoType(HashingAlgoType.sha512);
      final dataToSign =
          '_a7028ce7-aaa8-4c52-9cf4-b94ca3bdf971@alice:c2834cd4-bb16-4801-8abc-efe79cdceb8f';
      final dataInBytes = Uint8List.fromList(dataToSign.codeUnits);
      final signatureInBytes = pkamSigningAlgo.sign(dataInBytes);
      final publicKeyString = pkamKeyPair.atPublicKey.publicKey;
      var verifyResult = pkamSigningAlgo.verify(dataInBytes, signatureInBytes,
          publicKey: publicKeyString);
      expect(verifyResult, true);
    });
  });
}
