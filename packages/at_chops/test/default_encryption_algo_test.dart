import 'dart:convert';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';
import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group(
      'A group of tests for encryption/decryption by passing public/private key',
      () {
    test('Test asymmetric encryption/decryption using rsa 2048', () {
      var defaultEncryptionAlgo = DefaultEncryptionAlgo();
      var rsa2048KeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      var rsaPublicKey = rsa2048KeyPair.atPublicKey;
      var dataToEncrypt = 'Hello World12!@';
      var encryptedData = defaultEncryptionAlgo
          .encrypt(utf8.encode(dataToEncrypt), atPublicKey: rsaPublicKey);
      var rsaPrivateKey = rsa2048KeyPair.atPrivateKey;
      var decryptedData = defaultEncryptionAlgo.decrypt(encryptedData,
          atPrivateKey: rsaPrivateKey);
      expect(utf8.decode(decryptedData), dataToEncrypt);
    });
    test('Test encrypt throws exception when passed public key is null', () {
      var defaultEncryptionAlgo = DefaultEncryptionAlgo();
      var dataToEncrypt = 'Hello World12!@';
      AtPublicKey? publicKey;
      expect(
          () => defaultEncryptionAlgo.encrypt(utf8.encode(dataToEncrypt),
              atPublicKey: publicKey),
          throwsA(predicate((e) =>
              e is AtEncryptionException &&
              e.toString().contains('EncryptionKeypair/public key not set'))));
    });
    test('Test decrypt throws exception when passed private key is null', () {
      var defaultEncryptionAlgo = DefaultEncryptionAlgo();
      var encryptedData = 'random data';
      AtPrivateKey? privateKey;
      expect(
          () => defaultEncryptionAlgo.decrypt(utf8.encode(encryptedData),
              atPrivateKey: privateKey),
          throwsA(predicate((e) =>
              e is AtDecryptionException &&
              e.toString().contains('EncryptionKeypair/public key not set'))));
    });
  });

  group(
      'A group of tests for encryption/decryption by setting encryption key pair',
      () {
    test('Test asymmetric encryption/decryption using rsa 2048 key pair', () {
      var rsa2048KeyPair = AtChopsUtil.generateAtEncryptionKeyPair();
      var defaultEncryptionAlgo =
          DefaultEncryptionAlgo.fromKeyPair(rsa2048KeyPair);
      var dataToEncrypt = 'Hello World12!@';
      var encryptedData =
          defaultEncryptionAlgo.encrypt(utf8.encode(dataToEncrypt));
      var decryptedData = defaultEncryptionAlgo.decrypt(encryptedData);
      expect(utf8.decode(decryptedData), dataToEncrypt);
    });
    test('Test encrypt throws exception when encryption keypair is null', () {
      var defaultEncryptionAlgo = DefaultEncryptionAlgo.fromKeyPair(null);
      var dataToEncrypt = 'Hello World12!@';
      expect(
          () => defaultEncryptionAlgo.encrypt(utf8.encode(dataToEncrypt)),
          throwsA(predicate((e) =>
              e is AtEncryptionException &&
              e.toString().contains('EncryptionKeypair/public key not set'))));
    });
    test('Test decrypt throws exception when encryption keypair is null', () {
      var defaultEncryptionAlgo = DefaultEncryptionAlgo.fromKeyPair(null);
      var encryptedData = 'random data';
      expect(
          () => defaultEncryptionAlgo.decrypt(utf8.encode(encryptedData)),
          throwsA(predicate((e) =>
              e is AtDecryptionException &&
              e.toString().contains('EncryptionKeypair/public key not set'))));
    });
  });
}
