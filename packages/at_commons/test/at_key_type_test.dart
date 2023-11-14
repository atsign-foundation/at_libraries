import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/utils/at_key_regex_utils.dart';
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

    test(
        'Test malformed key cached:public:cached:public:privateaccount.wavi@dying36dragonfly',
        () {
      var keyType = AtKey.getKeyType(
          'cached:public:cached:public:privateaccount.wavi@dying36dragonfly',
          enforceNameSpace: false);
      expect(keyType, equals(KeyType.invalidKey));
    });

    test('Test malformed key public:@public:image.wavi@colin', () {
      var keyType = AtKey.getKeyType('public:@public:image.wavi@colin',
          enforceNameSpace: false);
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

    test('Test reserved key type for latest notification id', () {
      var keyType = AtKey.getKeyType('_latestNotificationIdv2');
      expect(keyType, equals(KeyType.reservedKey));
    });

    test('A positive test to validate reserved key type', () {
      var keyTypeList = [];
      // keys with atsign
      keyTypeList.add('${AtConstants.atBlocklist}@☎️_0002');
      keyTypeList.add('@bob:${AtConstants.atEncryptionSharedKey}@alice');
      keyTypeList.add('@allen:${AtConstants.atSigningPrivateKey}@allen');
      keyTypeList.add('${AtConstants.atEncryptionPublicKey}@owner');
      keyTypeList.add('public:signing_publickey@alice');
      keyTypeList.add('public:signing_publickey@☎️_0002');
      // keys without atsign
      keyTypeList.add(AtConstants.atPkamPublicKey);
      keyTypeList.add(AtConstants.atPkamPrivateKey);
      keyTypeList.add(AtConstants.atEncryptionPrivateKey);
      keyTypeList.add(AtConstants.atEncryptionSelfKey);
      keyTypeList.add(AtConstants.atCramSecret);
      keyTypeList.add(AtConstants.atCramSecretDeleted);
      keyTypeList.add(AtConstants.atSigningKeypairGenerated);
      keyTypeList.add(AtConstants.commitLogCompactionKey);
      keyTypeList.add(AtConstants.accessLogCompactionKey);
      keyTypeList.add(AtConstants.notificationCompactionKey);
      keyTypeList.add('configkey');

      for (var key in keyTypeList) {
        var type = RegexUtil.keyType(key, false);
        print('$key -> $type');
        expect(type == KeyType.reservedKey, true);
      }
    });

    test('Validate no false positives for reserved keys with atsign', () {
      var keyTypeList = [];
      var fails = [];
      // these keys are supposed to have atsigns at the end
      // to test a negative case, the @atsign at the end has been removed
      keyTypeList.add('public:publickey');
      keyTypeList.add('public:signing_publickey');
      keyTypeList.add(AtConstants.atBlocklist);
      keyTypeList.add('@bob:${AtConstants.atEncryptionSharedKey}');
      keyTypeList.add(AtConstants.atEncryptionSharedKey);
      keyTypeList.add('@allen:${AtConstants.atSigningPrivateKey}');
      keyTypeList.add(AtConstants.atSigningPrivateKey);

      for (var key in keyTypeList) {
        var type = RegexUtil.keyType(key, false);
        if (type != KeyType.invalidKey) {
          fails.add('got $type for $key - expected KeyType.invalidKey');
        }
      }
      expect(fails, []);
    });

    test('Validate no false positives for reserved keys without atsign', (){
      var keysList = [];
      // the following keys are not supposed to have an atsign at the end
      // for the sake of testing a negative case, atsigns have been appended
      // to the keys
      keysList.add('${AtConstants.atPkamPublicKey}@alice123');
      keysList.add('${AtConstants.atPkamPrivateKey}@alice123');
      keysList.add('${AtConstants.atEncryptionPrivateKey}@alice123');
      keysList.add('${AtConstants.atEncryptionSelfKey}@alice123');
      keysList.add('${AtConstants.atCramSecret}@alice123');
      keysList.add('${AtConstants.atCramSecretDeleted}@alice123');
      keysList.add('${AtConstants.atSigningKeypairGenerated}@alice123');
      keysList.add('${AtConstants.commitLogCompactionKey}@alice123');
      keysList.add('${AtConstants.accessLogCompactionKey}@alice123');
      keysList.add('${AtConstants.notificationCompactionKey}@alice123');
      keysList.add('configkey@alice123');

      for (var key in keysList){
        var type = RegexUtil.keyType(key, false);
        print('$key -> $type');
        expect(type, isNot(KeyType.reservedKey));
      }
    });
  });
}
