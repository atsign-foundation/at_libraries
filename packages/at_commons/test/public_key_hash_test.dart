import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests to verify public key hash methods', () {
    test('Test to verify toJson method', () {
      final publicKeyHash =
          PublicKeyHash('randomhash', PublicKeyHashingAlgo.sha512);
      var toJson = publicKeyHash.toJson();
      expect(toJson['hash'], 'randomhash');
      expect(toJson['algo'], 'sha512');
    });
    test('Test to verify fromJson method', () {
      var jsonMap = {};
      jsonMap['hash'] = 'randomhash';
      jsonMap['algo'] = 'sha256';
      final publicKeyHash = PublicKeyHash.fromJson(jsonMap);
      expect(publicKeyHash, isNotNull);
      expect(publicKeyHash?.hash, 'randomhash');
      expect(publicKeyHash?.publicKeyHashingAlgo, PublicKeyHashingAlgo.sha256);
    });
    test('Test to verify equals operator two objects equals', () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash', PublicKeyHashingAlgo.sha512);
      expect(publicKeyHash_1 == publicKeyHash_2, true);
    });
    test('Test to verify equals operator two objects different hash', () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash_1', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash_2', PublicKeyHashingAlgo.sha512);
      expect(publicKeyHash_1 == publicKeyHash_2, false);
    });
    test('Test to verify equals operator two objects different hash algo', () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash_1', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash_2', PublicKeyHashingAlgo.sha256);
      expect(publicKeyHash_1 == publicKeyHash_2, false);
    });
    test('Test to verify hashcodes are same - two objects equals', () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash', PublicKeyHashingAlgo.sha512);
      equals(publicKeyHash_1.hashCode, publicKeyHash_2.hashCode);
    });
    test('Test to verify hashcodes are different - two objects different hash',
        () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash_1', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash_2', PublicKeyHashingAlgo.sha512);
      expect(publicKeyHash_1.hashCode == publicKeyHash_2.hashCode, false);
    });
    test(
        'Test to verify hashcodes are different - two objects different hash algo',
        () {
      final publicKeyHash_1 =
          PublicKeyHash('randomhash_1', PublicKeyHashingAlgo.sha512);
      final publicKeyHash_2 =
          PublicKeyHash('randomhash_2', PublicKeyHashingAlgo.sha256);
      expect(publicKeyHash_1.hashCode == publicKeyHash_2.hashCode, false);
    });
  });
}
