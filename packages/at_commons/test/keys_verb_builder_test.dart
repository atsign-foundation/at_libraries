import 'package:at_commons/src/verb/keys_verb_builder.dart';
import 'package:test/test.dart';

void main() {
  group('A group of keys verb builder tests', () {
    test('test check param method', () {
      final keysVerbBuilder = KeysVerbBuilder('get')..visibility = 'private';
      expect(keysVerbBuilder.checkParams(), true);
    });

    test('test get private keys', () {
      final keysVerbBuilder = KeysVerbBuilder('get')..visibility = 'private';
      expect(keysVerbBuilder.buildCommand(), 'keys:get:private\n');
    });

    test('test get self keys', () {
      final keysVerbBuilder = KeysVerbBuilder('get')..visibility = 'self';
      expect(keysVerbBuilder.buildCommand(), 'keys:get:self\n');
    });

    test('test get public keys', () {
      final keysVerbBuilder = KeysVerbBuilder('get')..visibility = 'public';
      expect(keysVerbBuilder.buildCommand(), 'keys:get:public\n');
    });

    test('test get private key by keyname', () {
      final keysVerbBuilder = KeysVerbBuilder('get')
        ..visibility = 'private'
        ..keyName = 'mykey';
      expect(
          keysVerbBuilder.buildCommand(), 'keys:get:private:keyName:mykey\n');
    });

    test('test get self key by keyname', () {
      final keysVerbBuilder = KeysVerbBuilder('get')
        ..visibility = 'self'
        ..keyName = 'mykey';
      expect(keysVerbBuilder.buildCommand(), 'keys:get:self:keyName:mykey\n');
    });
    test('test get public key by keyname', () {
      final keysVerbBuilder = KeysVerbBuilder('get')
        ..visibility = 'public'
        ..keyName = 'mykey';
      expect(keysVerbBuilder.buildCommand(), 'keys:get:public:keyName:mykey\n');
    });
    test('test put public key', () {
      final keysVerbBuilder = KeysVerbBuilder('put')
        ..visibility = 'public'
        ..keyName = 'encryptionPublicKey'
        ..namespace = '__global'
        ..keyType = 'rsa2048'
        ..value = 'abcd1234';
      expect(keysVerbBuilder.buildCommand(),
          'keys:put:public:keyName:encryptionPublicKey:namespace:__global:keyType:rsa2048:abcd1234\n');
    });

    test('test put private key', () {
      final keysVerbBuilder = KeysVerbBuilder('put')
        ..visibility = 'private'
        ..keyName = 'secretKey'
        ..namespace = '__private'
        ..keyType = 'aes256'
        ..value = 'abcd1234';
      expect(keysVerbBuilder.buildCommand(),
          'keys:put:private:keyName:secretKey:namespace:__private:keyType:aes256:abcd1234\n');
    });

    test('test put self key', () {
      final keysVerbBuilder = KeysVerbBuilder('put')
        ..visibility = 'self'
        ..keyName = 'selfkey'
        ..namespace = '__global'
        ..keyType = 'aes256'
        ..encryptionKeyName = 'firstKey'
        ..value = 'zcsfsdff';
      expect(keysVerbBuilder.buildCommand(),
          'keys:put:self:keyName:selfkey:namespace:__global:keyType:aes256:encryptionKeyName:firstKey:zcsfsdff\n');
    });
  });
}
