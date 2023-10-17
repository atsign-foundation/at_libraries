import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/keystore/at_key_builder_impl.dart';
import 'package:test/test.dart';

void main() {
  group('A group of positive test to construct a atKey', () {
    test('toString and fromString with namespace', () {
      var fromAtsign = '@alice';
      var toAtsign = '@bob';
      var metaData = Metadata()
        ..isPublic = false
        ..isEncrypted = true
        ..namespaceAware = true
        ..ttr = -1
        ..ttl = 10000;

      var inKey = AtKey()
        ..key = 'foo.bar'
        ..sharedBy = fromAtsign
        ..sharedWith = toAtsign
        ..namespace = 'attalk'
        ..metadata = metaData;

      expect(inKey.toString(), "@bob:foo.bar.attalk@alice");

      var outKey = AtKey.fromString(inKey.toString());
      expect(outKey.toString(), inKey.toString());
      expect(outKey.key, 'foo.bar');
      expect(outKey.namespace, 'attalk');
      expect(outKey.metadata!.isPublic, false);
      expect(outKey.isLocal, false);
    });

    test('Test to verify a public key', () {
      var testKey = 'public:phone@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.sharedWith, null);
      expect(atKey.isLocal, false);
      expect(atKey.metadata!.isPublic, true);
      expect(atKey.metadata!.namespaceAware, false);
      expect(atKey.toString(), testKey);
    });

    test('Test to verify protected key', () {
      var testKey = '@alice:phone@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.sharedWith, '@alice');
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey);
    });

    test('Test to verify private key', () {
      var testKey = 'phone@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.sharedWith, null);
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey);
    });

    test('Test to verify cached:shared key', () {
      var testKey = 'cached:@alice:phone@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.sharedWith, '@alice');
      expect(atKey.metadata!.isCached, true);
      expect(atKey.metadata!.namespaceAware, false);
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey);
    });

    test('Test to verify cached:shared key with namespace', () {
      var testKey = 'cached:@alice:phone.unit_test@charlie';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedBy, '@charlie');
      expect(atKey.sharedWith, '@alice');
      expect(atKey.metadata!.isCached, true);
      expect(atKey.namespace, 'unit_test');
      expect(atKey.metadata!.namespaceAware, true);
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey);
    });

    test('Test to verify cached:public key', () {
      var testKey = 'cached:public:test_key@demo';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.sharedWith, null);
      expect(atKey.sharedBy, '@demo');
      expect(atKey.key, 'test_key');
      expect(atKey.metadata!.isCached, true);
      expect(atKey.metadata!.isPublic, true);
    });

    test('Test to verify cached:public key with namespace', () {
      var testKey = 'cached:public:test_key.unit_test@demo';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.sharedWith, null);
      expect(atKey.sharedBy, '@demo');
      expect(atKey.key, 'test_key');
      expect(atKey.metadata!.isCached, true);
      expect(atKey.metadata!.isPublic, true);
      expect(atKey.namespace, 'unit_test');
      expect(atKey.metadata!.namespaceAware, true);
    });

    test('Test to verify pkam private key', () {
      var atKey = AtKey.fromString(AtConstants.atPkamPrivateKey);
      expect(atKey.key, AtConstants.atPkamPrivateKey);
      expect(atKey.toString(), AtConstants.atPkamPrivateKey);
    });

    test('Test to verify pkam private key', () {
      var atKey = AtKey.fromString(AtConstants.atPkamPublicKey);
      expect(atKey.key, AtConstants.atPkamPublicKey);
      expect(atKey.toString(), AtConstants.atPkamPublicKey);
    });

    test('Test to verify key with namespace', () {
      var testKey = '@alice:phone.buzz@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedWith, '@alice');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.metadata!.namespaceAware, true);
      expect(atKey.toString(), testKey);
    });
  });

  group(
      'A group of positive test to construct a atKey with uppercase characters to assert their conversion to lowercase',
      () {
    test('Assert key conversion to lowercase', () {
      var fromAtsign = '@aliCe🛠';
      var toAtsign = '@boB';
      var metaData = Metadata()..dataSignature = 'dfgDSFFkhkjh987686567464hbjh';

      AtKey atKey = AtKey()
        ..key = 'foo.Bar'
        ..sharedBy = fromAtsign
        ..sharedWith = toAtsign
        ..namespace = ''
        ..metadata = metaData;

      //assert that all components of the AtKey are converted to lowercase
      //key will not be converted to lowercase upon assigning
      expect(atKey.key, 'foo.Bar');
      expect(atKey.namespace, null);
      expect(atKey.sharedBy, '@alice🛠');
      expect(atKey.sharedWith, '@bob');
      //assert that dataSignature is not converted to lowercase
      expect(atKey.metadata?.dataSignature, metaData.dataSignature);
    });
    test('toString and fromString with namespace', () {
      var fromAtsign = '@aliCe';
      var toAtsign = '@boB🛠';
      var metaData = Metadata()
        ..isPublic = false
        ..isEncrypted = true
        ..namespaceAware = true
        ..ttr = -1
        ..ttl = 10000;

      var inKey = AtKey()
        ..key = 'foo.Bar'
        ..sharedBy = fromAtsign
        ..sharedWith = toAtsign
        ..namespace = 'attAlk'
        ..metadata = metaData;

      expect(inKey.toString(), "@bob🛠:foo.bar.attalk@alice");

      var outKey = AtKey.fromString(inKey.toString());
      expect(outKey.toString(), inKey.toString());
      expect(outKey.key, 'foo.bar');
      expect(outKey.namespace, 'attalk');
      expect(outKey.metadata!.isPublic, false);
      expect(outKey.isLocal, false);
    });

    test('Test to verify a public key', () {
      var testKey = 'public:pHone@bOb';
      var atKey = AtKey.fromString(testKey);
      //key will not be converted to lower_case just upon assignment
      expect(atKey.key, 'pHone');
      //sharedBy will be converted to lower_case upon assignment
      expect(atKey.sharedBy, '@bob');
      //sharedWith will be converted to lower_case upon assignment
      expect(atKey.sharedWith, null);
      expect(atKey.isLocal, false);
      expect(atKey.metadata!.isPublic, true);
      expect(atKey.metadata!.namespaceAware, false);
      //toString method will convert entire key to lower_case
      expect(atKey.toString(), testKey.toLowerCase());
    });

    test('Test to verify protected key', () {
      var testKey = '@aliCe:pHone@boB';
      var atKey = AtKey.fromString(testKey);
      //key will not be converted to lower_case just upon assignment
      expect(atKey.key, 'pHone');
      //sharedBy will be converted to lower_case upon assignment
      expect(atKey.sharedBy, '@bob');
      //sharedWith will be converted to lower_case upon assignment
      expect(atKey.sharedWith, '@alice');
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      //toString method will convert entire key to lower_case
      expect(atKey.toString(), testKey.toLowerCase());
    });

    test('Test to verify private key', () {
      var testKey = 'phoNe@bOb';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phoNe');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.sharedWith, null);
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey.toLowerCase());
    });

    test('Test to verify cached key', () {
      var testKey = 'cached:@aliCe:pHone@Bob';
      var atKey = AtKey.fromString(testKey);
      //key will not be converted to lower_case just upon assignment
      expect(atKey.key, 'pHone');
      //sharedBy will be converted to lower_case upon assignment
      expect(atKey.sharedBy, '@bob');
      //sharedWith will be converted to lower_case upon assignment
      expect(atKey.sharedWith, '@alice');
      expect(atKey.metadata!.isCached, true);
      expect(atKey.metadata!.namespaceAware, false);
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.toString(), testKey.toLowerCase());
    });

    test('Test to verify pkam private key', () {
      var atKey = AtKey.fromString(AtConstants.atPkamPrivateKey);
      expect(atKey.key, AtConstants.atPkamPrivateKey);
      expect(atKey.toString(), AtConstants.atPkamPrivateKey);
    });

    test('Test to verify pkam private key', () {
      var atKey = AtKey.fromString(AtConstants.atPkamPublicKey);
      expect(atKey.key, AtConstants.atPkamPublicKey);
      expect(atKey.toString(), AtConstants.atPkamPublicKey);
    });

    test('Test to verify key with namespace', () {
      var testKey = '@alice:phone.buzz@bob';
      var atKey = AtKey.fromString(testKey);
      expect(atKey.key, 'phone');
      expect(atKey.sharedWith, '@alice');
      expect(atKey.sharedBy, '@bob');
      expect(atKey.metadata!.isPublic, false);
      expect(atKey.isLocal, false);
      expect(atKey.metadata!.namespaceAware, true);
      expect(atKey.toString(), testKey);
    });
  });

  group('A group a negative test cases', () {
    test('Test to verify invalid syntax exception is thrown', () {
      var key = 'phone.buzz';
      expect(
          () => AtKey.fromString(key),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == '$key is not well-formed key')));
    });

    test('Test cannot set sharedWith if isPublic is true', () {
      expect(
          () => {
                AtKey()
                  ..metadata = (Metadata()..isPublic = true)
                  ..sharedBy = '@bob'
                  ..sharedWith = '@alice'
              },
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'isLocal or isPublic cannot be true when sharedWith is set')));
    });

    test('Test cannot set sharedWith if isLocal is true', () {
      expect(
          () => {
                AtKey()
                  ..isLocal = true
                  ..sharedBy = '@bob'
                  ..sharedWith = '@alice'
              },
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'isLocal or isPublic cannot be true when sharedWith is set')));
    });

    test('Test cannot set isLocal to true if sharedWith is non-null', () {
      expect(
          () => {
                AtKey()
                  ..sharedBy = '@bob'
                  ..sharedWith = '@alice'
                  ..isLocal = true
              },
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'sharedWith must be null when isLocal is set to true')));
    });
  });

  group('A group of tests to validate the AtKey builder instances', () {
    test('Validate public key builder', () {
      PublicKeyBuilder publicKeyBuilder =
          AtKey.public('phone', namespace: 'wavi');
      expect(publicKeyBuilder, isA<PublicKeyBuilder>());
      expect(publicKeyBuilder.build().toString(), 'public:phone.wavi');

      publicKeyBuilder =
          AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice');
      expect(publicKeyBuilder, isA<PublicKeyBuilder>());
      expect(publicKeyBuilder.build().toString(), 'public:phone.wavi@alice');
    });

    test('Validate the shared key builder', () {
      SharedKeyBuilder sharedKeyBuilder =
          AtKey.shared('phone', namespace: 'wavi')..sharedWith('@bob');
      expect(sharedKeyBuilder, isA<SharedKeyBuilder>());
      expect(sharedKeyBuilder.build().toString(), '@bob:phone.wavi');

      sharedKeyBuilder =
          AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice')
            ..sharedWith('@bob');
      expect(sharedKeyBuilder, isA<SharedKeyBuilder>());
      expect(sharedKeyBuilder.build().toString(), '@bob:phone.wavi@alice');
    });

    test('Validate the self key builder', () {
      SelfKeyBuilder selfKeyBuilder = AtKey.self('phone', namespace: 'wavi');
      expect(selfKeyBuilder, isA<SelfKeyBuilder>());
      expect(selfKeyBuilder.build().toString(), 'phone.wavi');

      selfKeyBuilder = AtKey.self('phone', namespace: 'wavi', sharedBy: '@bob');
      expect(selfKeyBuilder, isA<SelfKeyBuilder>());
      expect(selfKeyBuilder.build().toString(), 'phone.wavi@bob');
    });

    test('Validate the hidden key builder', () {
      PrivateKeyBuilder hiddenKeyBuilder =
          AtKey.private('phone', namespace: 'wavi');
      expect(hiddenKeyBuilder, isA<PrivateKeyBuilder>());
      expect(hiddenKeyBuilder.build().toString(), 'privatekey:phone.wavi');
    });
  });

  group('A group of tests to validate the AtKey instances', () {
    test('Test to verify the public key', () {
      AtKey atKey =
          AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice').build();
      expect(atKey, isA<PublicKey>());
      expect(atKey.toString(), 'public:phone.wavi@alice');
    });

    test('Test to verify the shared key', () {
      AtKey atKey =
          (AtKey.shared('image', namespace: 'wavi', sharedBy: '@alice')
                ..sharedWith('@bob'))
              .build();
      expect(atKey, isA<SharedKey>());
      expect(atKey.toString(), '@bob:image.wavi@alice');
    });

    test('Test to verify the self key', () {
      AtKey selfKey =
          AtKey.self('phone', namespace: 'wavi', sharedBy: '@alice').build();
      expect(selfKey, isA<SelfKey>());
      expect(selfKey.toString(), 'phone.wavi@alice');
    });

    test('Test to verify the hidden key', () {
      AtKey selfKey = AtKey.private('phone', namespace: 'wavi').build();
      expect(selfKey, isA<PrivateKey>());
      expect(selfKey.toString(), 'privatekey:phone.wavi');
    });
  });

  group('A group of negative test on toString method', () {
    test('test to verify key is null', () {
      var atKey = AtKey()
        ..sharedWith = '@alice'
        ..sharedBy = '@bob';
      expect(
          () => atKey.toString(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message == 'Key cannot be null or empty')));
    });

    test('test to verify key is empty', () {
      var atKey = AtKey()
        ..key = ''
        ..sharedWith = '@alice'
        ..sharedBy = '@bob';
      expect(
          () => atKey.toString(),
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message == 'Key cannot be null or empty')));
    });
  });

  group('A group of negative tests to validate AtKey', () {
    test('Test to verify AtException is thrown when key is empty', () {
      expect(
          () => (AtKey.public('', namespace: 'wavi')).build(),
          throwsA(predicate((dynamic e) =>
              e is AtException && e.message == 'Key cannot be empty')));
    });

    test(
        'Test to verify AtException is thrown when sharedWith is not populated for sharedKey',
        () {
      expect(
          () => (AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice'))
              .build(),
          throwsA(predicate((dynamic e) =>
              e is AtException && e.message == 'sharedWith cannot be empty')));
    });
  });

  group('Test public key creation', () {
    test('Test key and namespace with no ttl and ttb', () {
      AtKey atKey =
          AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice').build();
      expect(atKey.key, equals('phone'));
      expect(atKey.sharedBy, equals('@alice'));
      expect(atKey.namespace, equals('wavi'));
      expect(atKey.metadata!.ttl, equals(null));
      expect(atKey.metadata!.ttb, equals(null));
      expect(atKey.metadata!.isPublic, equals(true));
      expect(atKey.metadata!.isBinary, equals(false));
      expect(atKey.metadata!.isCached, equals(false));
      expect(atKey.toString(), 'public:phone.wavi@alice');
    });

    test('Test key and namespace with ttl and ttb', () {
      AtKey atKey =
          (AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice')
                ..timeToLive(1000)
                ..timeToBirth(2000))
              .build();

      expect(atKey.key, equals('phone'));
      expect(atKey.sharedBy, equals('@alice'));
      expect(atKey.namespace, equals('wavi'));
      expect(atKey.metadata!.ttl, equals(1000));
      expect(atKey.metadata!.ttb, equals(2000));
      expect(atKey.metadata!.isPublic, equals(true));
      expect(atKey.metadata!.isPublic, equals(true));
      expect(atKey.metadata!.isBinary, equals(false));
      expect(atKey.metadata!.isCached, equals(false));
      expect(atKey.toString(), 'public:phone.wavi@alice');
    });
  });

  group('Test shared key creation', () {
    test('Test shared key without caching', () {
      AtKey atKey =
          (AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice')
                ..sharedWith('@bob'))
              .build();

      expect(atKey.key, equals('phone'));
      expect(atKey.sharedBy, equals('@alice'));
      expect(atKey.namespace, equals('wavi'));
      expect(atKey.sharedWith, equals('@bob'));
      expect(atKey.metadata!.ttl, equals(null));
      expect(atKey.metadata!.ttb, equals(null));
      expect(atKey.metadata!.isPublic, equals(false));
      expect(atKey.metadata!.isBinary, equals(false));
      expect(atKey.metadata!.isCached, equals(false));
      expect(atKey.toString(), '@bob:phone.wavi@alice');
    });

    test('Test shared key with caching', () {
      AtKey atKey =
          (AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice')
                ..sharedWith('@bob')
                ..cache(1000, true))
              .build();

      expect(atKey.key, equals('phone'));
      expect(atKey.sharedBy, equals('@alice'));
      expect(atKey.namespace, equals('wavi'));
      expect(atKey.sharedWith, equals('@bob'));
      expect(atKey.metadata!.ttr, equals(1000));
      expect(atKey.metadata!.ccd, equals(true));
      expect(atKey.metadata!.ttl, equals(null));
      expect(atKey.metadata!.ttb, equals(null));
      expect(atKey.metadata!.isPublic, equals(false));
      expect(atKey.metadata!.isBinary, equals(false));
      expect(atKey.toString(), '@bob:phone.wavi@alice');
    });
  });

  group('A group of tests to validate the public keys', () {
    test('validate a public key with namespace', () {
      var validationResult = AtKeyValidators.get().validate(
          'public:phone.me@alice', ValidationContext()..atSign = '@alice');
      expect(validationResult.isValid, true);
    });

    test('validate a public key with setting validation context', () {
      var validationResult = AtKeyValidators.get().validate(
          'public:phone.me@alice',
          ValidationContext()
            ..type = KeyType.publicKey
            ..atSign = '@alice');
      expect(validationResult.isValid, true);
    });
  });

  group('A group of tests to validate the self keys', () {
    test('validate a self key with namespace', () {
      var validationResult = AtKeyValidators.get()
          .validate('phone.me@alice', ValidationContext()..atSign = '@alice');
      expect(validationResult.isValid, true);
    });

    test('validate a self key with setting validation context', () {
      var validationResult = AtKeyValidators.get().validate(
          'phone.me@alice',
          ValidationContext()
            ..type = KeyType.selfKey
            ..atSign = '@alice');
      expect(validationResult.isValid, true);
    });

    test('validate a self key with sharedWith populated', () {
      var validationResult = AtKeyValidators.get().validate(
          '@alice:phone.me@alice',
          ValidationContext()
            ..atSign = '@alice'
            ..type = KeyType.selfKey);
      expect(validationResult.isValid, true);
    });
  });

  group('A group of tests to validate the shared keys', () {
    test('validate a shared key with namespace', () {
      var validationResult = AtKeyValidators.get().validate(
          '@bob:phone.me@alice', ValidationContext()..atSign = '@alice');
      expect(validationResult.isValid, true);
    });

    test('validate a shared key with setting validation context', () {
      var validationResult = AtKeyValidators.get().validate(
          '@bob:phone.me@alice',
          ValidationContext()
            ..atSign = '@alice'
            ..type = KeyType.sharedKey);
      expect(validationResult.isValid, true);
    });

    test('Verify a shared key without sharedWith populated throws error', () {
      var validationResult = AtKeyValidators.get().validate(
          'phone.me@alice',
          ValidationContext()
            ..atSign = '@alice'
            ..type = KeyType.sharedKey);
      expect(validationResult.isValid, false);
    });
  });

  group('A group of tests to validate the cached shared keys', () {
    test('validate a cached shared key with namespace', () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:@bob:phone.me@alice', ValidationContext()..atSign = '@bob');
      expect(validationResult.isValid, true);
    });

    test('validate a cached shared key with setting validation context', () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:@bob:phone.me@alice',
          ValidationContext()
            ..atSign = '@bob'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, true);
    });

    test(
        'validate a cached shared key throws error when owner is currentAtSign',
        () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:@bob:phone.me@alice',
          ValidationContext()
            ..atSign = 'alice'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, false);
      expect(validationResult.failureReason,
          'Owner of the key alice should not be same as the the current @sign alice for a cached key');
    });

    test('Verify a cached shared key without sharedWith populated throws error',
        () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:phone.me@alice',
          ValidationContext()
            ..atSign = '@alice'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, false);
    });
  });

  group('A group of tests to validate the cached public keys', () {
    test('validate a cached public key with namespace', () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:public:phone.me@alice', ValidationContext()..atSign = '@bob');
      expect(validationResult.isValid, true);
    });

    test('validate a cached shared key with setting validation context', () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:@bob:phone.me@alice',
          ValidationContext()
            ..atSign = '@bob'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, true);
    });

    test(
        'validate a cached shared key throws error when owner is currentAtSign',
        () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:@bob:phone.me@alice',
          ValidationContext()
            ..atSign = 'alice'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, false);
      expect(validationResult.failureReason,
          'Owner of the key alice should not be same as the the current @sign alice for a cached key');
    });

    test('Verify a cached shared key without sharedWith populated throws error',
        () {
      var validationResult = AtKeyValidators.get().validate(
          'cached:phone.me@alice',
          ValidationContext()
            ..atSign = '@alice'
            ..type = KeyType.cachedSharedKey);
      expect(validationResult.isValid, false);
    });
  });

  group('A group of tests to verify toString method', () {
    // public keys
    test('A test to verify a public key creation', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedBy = '@alice'
        ..metadata = (Metadata()..isPublic = true)
        ..namespace = 'wavi';
      expect('public:phone.wavi@alice', atKey.toString());
    });

    test('A test to verify a public key creation and conversion to lower_case',
        () {
      var atKey = AtKey()
        ..key = 'CELLphone'
        ..sharedBy = '@PRESIDENT'
        ..metadata = (Metadata()..isPublic = true)
        ..namespace = 'wavi';
      expect('public:cellphone.wavi@president', atKey.toString());
    });

    test(
        'A test to verify a public-key creation on a public key factory method',
        () {
      var atKey =
          AtKey.public('phone', namespace: 'wavi', sharedBy: '@alice').build();
      expect('public:phone.wavi@alice', atKey.toString());
    });

    test(
        'A test to verify a public-key creation on a public key conversion to lower_case',
        () {
      var atKey =
          AtKey.public('MOBILE', namespace: 'LTE', sharedBy: '@ANOnymous')
              .build();
      expect('public:mobile.lte@anonymous', atKey.toString());
    });

    // Shared keys
    test('A test to verify a sharedWith key creation', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedWith = '@bob'
        ..sharedBy = '@alice'
        ..namespace = 'wavi';
      expect('@bob:phone.wavi@alice', atKey.toString());
    });

    test(
        'A test to verify a sharedWith key creation and conversion to lower_case',
        () {
      var atKey = AtKey()
        ..key = 'phoneNEW'
        ..sharedWith = '@bobBY'
        ..sharedBy = '@aliceSTer'
        ..namespace = 'wavi';
      expect('@bobby:phonenew.wavi@alicester', atKey.toString());
    });

    test(
        'A test to verify a sharedWith key creation with static factory method',
        () {
      var atKey = (AtKey.shared('phone', namespace: 'wavi', sharedBy: '@alice')
            ..sharedWith('@bob'))
          .build();
      expect('@bob:phone.wavi@alice', atKey.toString());
    });

    test(
        'A test to verify a sharedWith key creation and conversion to lower_case',
        () {
      var atKey = (AtKey.shared('phONe', namespace: 'wAvi', sharedBy: '@alIce')
            ..sharedWith('@bob'))
          .build();
      expect('@bob:phone.wavi@alice', atKey.toString());
    });

    // Self keys
    test('A test to verify a self key creation', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedWith = '@alice'
        ..sharedBy = '@alice'
        ..namespace = 'wavi';
      expect('@alice:phone.wavi@alice', atKey.toString());
    });

    test('A test to verify a self key creation and conversion to lower_case',
        () {
      var atKey = AtKey()
        ..key = 'pHonE'
        ..sharedWith = '@Alice'
        ..sharedBy = '@aLiCe'
        ..namespace = 'wavI';
      expect('@alice:phone.wavi@alice', atKey.toString());
    });

    test('A test to verify a self key creation with static factory method', () {
      var atKey =
          AtKey.self('phone', namespace: 'wavi', sharedBy: '@alice').build();
      expect('phone.wavi@alice', atKey.toString());
    });

    test('A test to verify a self key conversion to lower_case', () {
      var atKey =
          AtKey.self('pHone', namespace: 'wAvi', sharedBy: '@aliCe').build();
      expect('phone.wavi@alice', atKey.toString());
    });

    test('Verify a self key creation without sharedWith using static factory',
        () {
      var atKey = SelfKey()
        ..key = 'phone'
        ..sharedBy = '@alice'
        ..namespace = 'wavi';
      expect('phone.wavi@alice', atKey.toString());
    });

    test('Verify a self key creation without sharedWith', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedBy = '@alice'
        ..namespace = 'wavi';
      expect('phone.wavi@alice', atKey.toString());
    });

    // Cached keys
    test('Verify a cached key creation', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedWith = '@bob'
        ..sharedBy = '@alice'
        ..metadata = (Metadata()..isCached = true)
        ..namespace = 'wavi';
      expect('cached:@bob:phone.wavi@alice', atKey.toString());
    });

    test('Verify a public cached key creation', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedBy = '@alice'
        ..metadata = (Metadata()
          ..isCached = true
          ..isPublic = true)
        ..namespace = 'wavi';
      expect('cached:public:phone.wavi@alice', atKey.toString());
    });

    //Private keys
    test('Verify a privatekey creation using static factory method', () {
      var atKey = PrivateKey()..key = 'at_secret';
      expect('privatekey:at_secret', atKey.toString());
    });

    test('Verify a privatekey creation', () {
      var atKey = AtKey()..key = 'privatekey:at_secret';
      expect('privatekey:at_secret', atKey.toString());
    });
  });

  group('A group of tests to validate local key', () {
    test('A test to verify toString on AtKey', () {
      var atKey = AtKey()
        ..key = 'phone'
        ..sharedBy = '@alice'
        ..namespace = 'wavi'
        ..isLocal = true;
      expect(atKey.toString(), 'local:phone.wavi@alice');
    });

    test('A test to verify toString on AtKey with local: in atKey', () {
      var atKey = AtKey()
        ..key = 'local:phoNe'
        ..sharedBy = '@alice'
        ..namespace = 'wavi'
        ..isLocal = true;
      expect(atKey.toString(), 'local:phone.wavi@alice');
    });

    test('A test to verify fromString on AtKey', () {
      var atKey = AtKey.fromString('local:phone.wavi@aliCe');
      expect(atKey.key, 'phone');
      expect(atKey.namespace, 'wavi');
      expect(atKey.sharedBy, '@alice');
      expect(atKey.isLocal, true);
    });

    test('A test to validate the creation of local key using static method',
        () {
      var atKey = AtKey.local('phone', '@alice', namespace: 'wavi').build();
      expect(atKey.key, 'phone');
      expect(atKey.namespace, 'wavi');
      expect(atKey.sharedBy, '@alice');
      expect(atKey.isLocal, true);
    });

    test(
        'A test to verify InvalidAtKey exception is thrown when sharedWith and isLocal are populated',
        () {
      expect(
          () => AtKey()
            ..key = 'phone'
            ..namespace = 'wavi'
            ..sharedWith = '@bob'
            ..sharedBy = '@alice'
            ..isLocal = true,
          throwsA(predicate((dynamic e) =>
              e is InvalidAtKeyException &&
              e.message ==
                  'sharedWith must be null when isLocal is set to true')));
    });

    test('A test to verify local key builder', () {
      var localKey = (LocalKeyBuilder()
            ..key('phone')
            ..sharedBy('@aliCe'))
          .build();
      expect(localKey, isA<LocalKey>());
      expect(localKey.isLocal, true);
      expect(localKey.toString(), 'local:phone@alice');
    });

    test('validate a local key with sharedBy populated', () {
      var localKey = (LocalKeyBuilder()
            ..key('phone')
            ..sharedBy('@alice'))
          .build();
      var validationResult = AtKeyValidators.get().validate(
          localKey.toString(), ValidationContext()..atSign = '@alice');
      expect(validationResult.isValid, true);
    });

    test('validate a local key with sharedBy not populated', () {
      var localKey = (LocalKeyBuilder()
            ..key('phone')
            ..sharedBy(''))
          .build();
      var validationResult = AtKeyValidators.get().validate(
          localKey.toString(), ValidationContext()..atSign = '@alice');
      expect(validationResult.isValid, false);
      expect(validationResult.failureReason, 'local:phone is not a valid key');
    });

    test('validate a local key with namespace not populated', () {
      var localKey = (LocalKeyBuilder()
            ..key('phone')
            ..sharedBy('@alice'))
          .build();
      var validationResult = AtKeyValidators.get().validate(
          localKey.toString(),
          ValidationContext()
            ..atSign = '@alice'
            ..enforceNamespace = true);
      expect(validationResult.isValid, false);
      expect(validationResult.failureReason,
          'local:phone@alice is not a valid key');
    });

    test('Test to verify LocalKey conversion to lower_case', () {
      var localKey =
          AtKey.local('tEstKey', '@aLice', namespace: 'tEst').build();
      expect(localKey.key, 'tEstKey');
      expect(localKey.sharedBy, '@alice');
      expect(localKey.namespace, 'test');
      expect(localKey.toString(), 'local:testkey.test@alice');
    });
  });
}
