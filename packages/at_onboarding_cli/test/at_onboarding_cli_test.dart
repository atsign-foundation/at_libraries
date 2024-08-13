import 'dart:convert';
import 'dart:io';

import 'package:at_auth/at_auth.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_persistence_secondary_server/at_persistence_secondary_server.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class MockAtLookupImpl extends Mock implements AtLookupImpl {}

class MockAtAuthImpl extends Mock implements AtAuth {}

class FakeAtAuthRequest extends Fake implements AtAuthRequest {}

class MockAtClient extends Mock implements AtClient {}

class MockEnrollmentBase extends Mock implements AtEnrollmentBase {}

void main() {
  AtSignLogger.root_level = 'INFO';
  AtLookupImpl mockAtLookup = MockAtLookupImpl();
  AtAuth mockAtAuth = MockAtAuthImpl();

  setUp(() {
    reset(mockAtLookup);
    reset(mockAtAuth);
    registerFallbackValue(FakeAtAuthRequest());
  });

  group('A group of tests to verify at_chops creation in onboarding_cli', () {
    setUp(() {
      reset(mockAtLookup);
      reset(mockAtAuth);
      registerFallbackValue(FakeAtAuthRequest());
    });

    test('A test to check authenticate true', () async {
      final atSign = '@alice🛠';
      AtOnboardingPreference onboardingPreference = AtOnboardingPreference()
        ..atKeysFilePath = 'test/data/@alice🛠_key.atKeys'
        ..namespace = 'unit_test';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, onboardingPreference);
      onboardingService.atLookUp = mockAtLookup;
      mockAtAuth.atChops = AtChopsImpl(AtChopsKeys());
      onboardingService.atAuth = mockAtAuth;
      onboardingService.atClient = await AtClientImpl.create(
          atSign, '.wavi', getAtClientPreferenceAlice());
      when(() => mockAtLookup.pkamAuthenticate())
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtAuth.authenticate(any())).thenAnswer(
          (_) => Future.value(AtAuthResponse(atSign)..isSuccessful = true));
      when(() => mockAtAuth.atChops)
          .thenAnswer((_) => AtChopsImpl(AtChopsKeys()));
      var authResult = await onboardingService.authenticate();
      expect(authResult, true);
    });
    // TODO: add more tests
    tearDown(() async => await tearDownFunc());
  });

  group('validate enrollment related operations', () {
    String atsign = '@alice_test';

    setUp(() async {
      await setupLocalStorage(atsign);
      reset(mockAtLookup);
      reset(mockAtAuth);
      registerFallbackValue(FakeAtAuthRequest());
      registerFallbackValue(EnrollVerbBuilder());
      registerFallbackValue(mockAtLookup);
      registerFallbackValue(EnrollmentRequest(
          appName: 'appName',
          deviceName: 'deviceName',
          otp: 'otp',
          namespaces: {}));
    });

    test('validate enrollment details being stored to LocalSecondary',
        () async {
      // setup dummy enrollment data
      String dummyEnrollmentId = '62212385-3b9f-4c98-8768-146f460c5ade';
      String appName = 'test_app';
      String deviceName = 'test_device';
      String otp = 'XXXXXX';
      Map<String, String> namespaces = {'test_namespace': 'rw'};

      // setup dependencies for mocking
      MockAtClient mockAtClient = MockAtClient();
      MockEnrollmentBase mockEnrollmentBase = MockEnrollmentBase();
      var keyStore = SecondaryPersistenceStoreFactory.getInstance()
          .getSecondaryPersistenceStore(atsign)
          ?.getSecondaryKeyStore();
      LocalSecondary localSecondary =
          LocalSecondary(mockAtClient, keyStore: keyStore);

      // mocking OnboardingServiceImpl
      AtOnboardingServiceImpl onboardingService =
          AtOnboardingServiceImpl(atsign, getOnboardingPreference());
      onboardingService.atClient = mockAtClient;
      onboardingService.enrollmentBase = mockEnrollmentBase;
      onboardingService.atLookUp = mockAtLookup;
      onboardingService.atAuth = mockAtAuth;

      // setup AtChopsKeys and AtAuthKeys
      AtEnrollmentResponse enrollmentResponse =
          AtEnrollmentResponse(dummyEnrollmentId, EnrollmentStatus.pending);
      AtChopsKeys atChopsKeys = getRandomAtChopsKeys();
      AtAuthKeys dummyAuthKeys = getAtAuthKeysFromAtChopsKeys(atChopsKeys);
      enrollmentResponse.atAuthKeys = dummyAuthKeys;

      // setup mock behaviour
      when(() => mockEnrollmentBase.submit(any(), any()))
          .thenAnswer((_) => Future.value(enrollmentResponse));
      when(() => mockAtLookup.pkamAuthenticate(enrollmentId: dummyEnrollmentId))
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtLookup.atChops).thenReturn(AtChopsImpl(atChopsKeys));
      when(() => mockAtClient.getCurrentAtSign()).thenReturn(atsign);
      when(() => mockAtClient.getLocalSecondary()).thenReturn(localSecondary);

      // mock EncryptionPrivateKey and SelfEncryption retrieval from server
      // server encrypts these keys with APKAMSymmetricKey
      String encryptedEncryptionPrivateKey = EncryptionUtil.encryptValue(
          dummyAuthKeys.defaultEncryptionPrivateKey!,
          dummyAuthKeys.apkamSymmetricKey!);
      String encryptedSelfEncryptionKey = EncryptionUtil.encryptValue(
          dummyAuthKeys.defaultSelfEncryptionKey!,
          dummyAuthKeys.apkamSymmetricKey!);
      String fetchEncryptionPrivateKeyCommand =
          'keys:get:keyName:$dummyEnrollmentId.${AtConstants.defaultEncryptionPrivateKey}.__manage$atsign\n';
      String fetchSelfEncryptionKeyCommand =
          'keys:get:keyName:$dummyEnrollmentId.${AtConstants.defaultSelfEncryptionKey}.__manage$atsign\n';
      String fetchEncryptionPrivateKeyResponse =
          'data:${jsonEncode({'value': encryptedEncryptionPrivateKey})}';
      String fetchSelfEncryptionKeyResponse =
          'data:${jsonEncode({'value': encryptedSelfEncryptionKey})}';
      when(() => mockAtLookup.executeCommand(fetchEncryptionPrivateKeyCommand,
              auth: true))
          .thenAnswer((_) => Future.value(fetchEncryptionPrivateKeyResponse));
      when(() => mockAtLookup.executeCommand(fetchSelfEncryptionKeyCommand,
              auth: true))
          .thenAnswer((_) => Future.value(fetchSelfEncryptionKeyResponse));

      // perform enrollment
      await onboardingService.enroll(appName, deviceName, otp, namespaces);

      // verify stored data in LocalSecondary
      AtData response =
          await localSecondary.keyStore?.get('local:$dummyEnrollmentId$atsign');
      Map<String, dynamic> jsonDecodedResponse = jsonDecode(response.data!);
      expect(jsonDecodedResponse['namespace'], namespaces);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('A group of tests related to generation of AtKeys', () {
    test(
        'A test to verify createAtKeys generates atKeys in the location specified in onboarding preference atKeysFilePath',
        () async {
      String atsign = '@alice_test';
      AtOnboardingPreference atOnboardingPreference = getOnboardingPreference()
        ..atKeysFilePath = '${Directory.current.path}/test/$atsign';
      AtOnboardingServiceImpl onboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);

      AtEnrollmentResponse atEnrollmentResponse =
          AtEnrollmentResponse('123', EnrollmentStatus.approved);

      RSAKeypair encryptionRsaKeyPair = onboardingService.generateRsaKeypair();
      atEnrollmentResponse.atAuthKeys = AtAuthKeys()
        ..enrollmentId = '123'
        ..defaultSelfEncryptionKey = onboardingService.generateAESKey()
        ..defaultEncryptionPublicKey = encryptionRsaKeyPair.publicKey.toString()
        ..defaultEncryptionPrivateKey =
            encryptionRsaKeyPair.privateKey.toString()
        ..apkamPrivateKey = encryptionRsaKeyPair.privateKey.toString()
        ..apkamPublicKey = encryptionRsaKeyPair.publicKey.toString()
        ..apkamSymmetricKey = onboardingService.generateAESKey();

      var f = await onboardingService.createAtKeysFile(atEnrollmentResponse);
      expect(f.path.endsWith('$atsign.atKeys'), true);

      File file = File(f.path);
      expect(file.existsSync(), true);
      // Delete the file at the end of the test.
      file.deleteSync(recursive: true);
    });
    ;
  });
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/storage').exists();
  if (isExists) {
    Directory('test/storage').deleteSync(recursive: true);
  }
}

AtClientPreference getAtClientPreferenceAlice() {
  var preference = AtClientPreference();
  preference.hiveStoragePath = 'test/storage/hive/client';
  preference.commitLogPath = 'test/storage/hive/client/commit';
  preference.isLocalStoreRequired = true;
  preference.rootDomain = 'vip.ve.atsign.zone';
  return preference;
}

AtOnboardingPreference getOnboardingPreference() {
  return AtOnboardingPreference()
    ..hiveStoragePath = 'test/storage/hive/client'
    ..commitLogPath = 'test/storage/hive/client/commit'
    ..atKeysFilePath = 'test/storage'
    ..isLocalStoreRequired = true;
}

// creates an instance of AtAuthKeys by using the keys in AtChopsKeys
AtAuthKeys getAtAuthKeysFromAtChopsKeys(AtChopsKeys atChopsKeys) {
  AtAuthKeys atAuthKeys = AtAuthKeys();

  atAuthKeys.apkamPublicKey = atChopsKeys.atPkamKeyPair?.atPublicKey.publicKey;
  atAuthKeys.apkamPrivateKey =
      atChopsKeys.atPkamKeyPair?.atPrivateKey.privateKey;
  atAuthKeys.defaultEncryptionPublicKey =
      atChopsKeys.atEncryptionKeyPair?.atPublicKey.publicKey;
  atAuthKeys.defaultEncryptionPrivateKey =
      atChopsKeys.atEncryptionKeyPair?.atPrivateKey.privateKey;
  atAuthKeys.defaultSelfEncryptionKey = atChopsKeys.selfEncryptionKey?.key;
  atAuthKeys.apkamSymmetricKey = atChopsKeys.apkamSymmetricKey?.key;

  return atAuthKeys;
}

AtChopsKeys getRandomAtChopsKeys() {
  AtEncryptionKeyPair encryptionKeyPair =
      AtChopsUtil.generateAtEncryptionKeyPair();
  AtPkamKeyPair pkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
  AtChopsKeys atChopsKeys = AtChopsKeys.create(encryptionKeyPair, pkamKeyPair);
  atChopsKeys.selfEncryptionKey =
      AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
  atChopsKeys.apkamSymmetricKey =
      AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);

  return atChopsKeys;
}

Future<void> setupLocalStorage(String atSign) async {
  String storageDir = 'test/storage/hive';
  var persistenceManager = SecondaryPersistenceStoreFactory.getInstance()
      .getSecondaryPersistenceStore(atSign)!;
  await persistenceManager.getHivePersistenceManager()!.init(storageDir);
}
