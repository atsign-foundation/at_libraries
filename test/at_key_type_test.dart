import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests to verify key types', () {
    test('Test to verify a public key type with namespace', () {
      var keyType = AtKey.getKeyType('public:phone.wavi@bob');
      expect(keyType, equals(KeyType.publicKey));
    });

    test('Test to verify a cached public key type with namespace', () {
      var keyType = AtKey.getKeyType('cached:public:phone.buzz@bob');
      expect(keyType, equals(KeyType.cachedPublicKey));
    });

    test('Test to verify a shared key type with namespace', () {
      var keyType = AtKey.getKeyType('@alice:phone.wavi@bob');
      expect(keyType, equals(KeyType.sharedKey));
    });

    test('Test to verify a cached shared key type with namespace', () {
      var keyType = AtKey.getKeyType('cached:@alice:phone.buzz@bob');
      expect(keyType, equals(KeyType.cachedSharedKey));
    });

    test('Test to verify self key type with namespace', () {
      var keyType = AtKey.getKeyType('@bob:phone.buzz@bob');
      expect(keyType, equals(KeyType.selfKey));
    });

    test('Test to verify local key type with namespace', () {
      var keyType = AtKey.getKeyType('local:latestNotification.wavi@bob',
          enforceNameSpace: true);
      expect(keyType, equals(KeyType.localKey));
    });
  });
  group('A group of tests to check invalid key types', () {
    test('Test public key type without namespace', () {
      var keyType =
          AtKey.getKeyType('public:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });

    test('Test cached public key type without namespace', () {
      var keyType =
          AtKey.getKeyType('cached:public:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });

    test('Test shared key type without namespace', () {
      var keyType =
          AtKey.getKeyType('@alice:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });

    test('Test cached shared key type without namespace', () {
      var keyType =
          AtKey.getKeyType('cached:@alice:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });

    test('Test self key type without sharedWith atsign and without namespace',
        () {
      var keyType = AtKey.getKeyType('phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });
    test('Test self key type with atsign and without namespace', () {
      var keyType = AtKey.getKeyType('@bob:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });
    test('Test local key type with atsign and without namespace', () {
      var keyType = AtKey.getKeyType('local:phone@bob', enforceNameSpace: true);
      expect(keyType, equals(KeyType.invalidKey));
    });
  });

  group('A group of tests to check reserved key types', () {
    test('Test reserved key type for shared_key', () {
      var keyType = AtKey.getKeyType('@bob:shared_key@alice');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for encryption publickey', () {
      var keyType = AtKey.getKeyType('public:publickey@alice');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for self encryption key', () {
      var keyType = AtKey.getKeyType('privatekey:self_encryption_key');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for signing private key', () {
      var keyType = AtKey.getKeyType('@alice:signing_privatekey@alice');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for public session key', () {
      var keyType = AtKey.getKeyType(
          'public:_a29464d0-1f2d-4216-b903-031963bc4ab3@alice');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for latest notification id', () {
      var keyType = AtKey.getKeyType('_latestNotificationIdv2');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for signing public key', () {
      var keyType = AtKey.getKeyType('public:signing_publickey@colin');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for commit log compaction key', () {
      var keyType = AtKey.getKeyType('privatekey:commitLogCompactionStats');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for access log compaction key', () {
      var keyType = AtKey.getKeyType('privatekey:accessLogCompactionStats');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for cram secret deleted', () {
      var keyType = AtKey.getKeyType('privatekey:at_secret_deleted');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for cram secret', () {
      var keyType = AtKey.getKeyType('privatekey:at_secret');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('Test reserved key type for config key (blocklist/allowlist)', () {
      var keyType = AtKey.getKeyType('configkey');
      expect(keyType, equals(KeyType.reservedKey));
    });
  });
}
