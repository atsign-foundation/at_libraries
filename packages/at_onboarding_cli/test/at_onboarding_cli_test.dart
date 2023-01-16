import 'dart:io';

import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:mocktail/mocktail.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_client/at_client.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demo;

void main() {
  AtLookupImpl mockAtLookup = MockAtLookupImpl();
  setUp(() {
    reset(mockAtLookup);
  });
  group('A group of tests to verify at_chops creation in onboarding_cli', () {
    test('A test to whether at_chops instance is set on authenticate',
        () async {
      final atSign = '@alice🛠';
      AtOnboardingPreference onboardingPreference = AtOnboardingPreference()
        ..atKeysFilePath = 'test/data/@alice🛠.atKeys';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, onboardingPreference);
      onboardingService.atLookUp = mockAtLookup;
      onboardingService.atClient =
          await AtClientImpl.create(atSign, '.wavi', getAlicePreference());
      when(() => mockAtLookup.pkamAuthenticate())
          .thenAnswer((_) => Future.value(true));
      await onboardingService.authenticate();
      final atChops = onboardingService.atClient?.atChops;
      expect(atChops, isNotNull);
      expect(atChops?.atChopsKeys, isNotNull);
    });
    test('A test to check whether at_chops keys are set correctly', () async {
      final atSign = '@alice🛠';
      AtOnboardingPreference onboardingPreference = AtOnboardingPreference()
        ..atKeysFilePath = 'test/data/@alice🛠.atKeys';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, onboardingPreference);
      onboardingService.atLookUp = mockAtLookup;
      onboardingService.atClient =
          await AtClientImpl.create(atSign, '.wavi', getAlicePreference());
      when(() => mockAtLookup.pkamAuthenticate())
          .thenAnswer((_) => Future.value(true));
      await onboardingService.authenticate();
      final atChops = onboardingService.atClient?.atChops;
      expect(atChops, isNotNull);
      expect(atChops!.atChopsKeys.atEncryptionKeyPair?.atPublicKey, isNotNull);
      expect(atChops.atChopsKeys.atEncryptionKeyPair!.atPublicKey.publicKey,
          at_demo.encryptionPublicKeyMap[atSign]);
      expect(atChops.atChopsKeys.atEncryptionKeyPair?.atPrivateKey, isNotNull);
      expect(atChops.atChopsKeys.atEncryptionKeyPair!.atPrivateKey.privateKey,
          at_demo.encryptionPrivateKeyMap[atSign]);
      expect(atChops.atChopsKeys.atPkamKeyPair?.atPublicKey, isNotNull);
      expect(atChops.atChopsKeys.atPkamKeyPair!.atPublicKey.publicKey,
          at_demo.pkamPublicKeyMap[atSign]);
      expect(atChops.atChopsKeys.atPkamKeyPair?.atPrivateKey, isNotNull);
      expect(atChops.atChopsKeys.atPkamKeyPair!.atPrivateKey.privateKey,
          at_demo.pkamPrivateKeyMap[atSign]);
    });
    tearDown(() async => await tearDownFunc());
  });
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/hive').exists();
  if (isExists) {
    Directory('test/hive').deleteSync(recursive: true);
  }
}

class MockAtLookupImpl extends Mock implements AtLookupImpl {}

AtClientPreference getAlicePreference() {
  var preference = AtClientPreference();
  preference.hiveStoragePath = 'test/hive/client';
  preference.commitLogPath = 'test/hive/client/commit';
  preference.isLocalStoreRequired = true;
  preference.rootDomain = 'vip.ve.atsign.zone';
  return preference;
}
