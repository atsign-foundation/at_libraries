import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_client/at_client.dart';
import 'package:at_auth/at_auth.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class MockAtLookupImpl extends Mock implements AtLookupImpl {}

class MockAtAuthImpl extends Mock implements AtAuthImpl {}

class FakeAtAuthRequest extends Fake implements AtAuthRequest {}

void main() {
  AtLookupImpl mockAtLookup = MockAtLookupImpl();
  AtAuthImpl mockAtAuth = MockAtAuthImpl();
  setUp(() {
    reset(mockAtLookup);
    reset(mockAtAuth);
    registerFallbackValue(FakeAtAuthRequest());
  });
  group('A group of tests to verify at_chops creation in onboarding_cli', () {
    AtSignLogger.root_level = 'FINER';
    test('A test to check authenticate true', () async {
      final atSign = '@alice🛠';
      AtOnboardingPreference onboardingPreference = AtOnboardingPreference()
        ..atKeysFilePath = 'test/data/@alice🛠.atKeys';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, onboardingPreference);
      onboardingService.atLookUp = mockAtLookup;
      mockAtAuth.atChops = AtChopsImpl(AtChopsKeys());
      onboardingService.atAuth = mockAtAuth;
      onboardingService.atClient =
          await AtClientImpl.create(atSign, '.wavi', getAlicePreference());
      when(() => mockAtLookup.pkamAuthenticate())
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtAuth.authenticate(any())).thenAnswer(
          (_) => Future.value(AtAuthResponse(atSign)..isSuccessful = true));
      when(() => mockAtAuth.atChops)
          .thenAnswer((_) => AtChopsImpl(AtChopsKeys()));
      var authResult = await onboardingService.authenticate();
      expect(authResult, true);
    });
    //#TODO add more tests
    tearDown(() async => await tearDownFunc());
  });
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/hive').exists();
  if (isExists) {
    Directory('test/hive').deleteSync(recursive: true);
  }
}

AtClientPreference getAlicePreference() {
  var preference = AtClientPreference();
  preference.hiveStoragePath = 'test/hive/client';
  preference.commitLogPath = 'test/hive/client/commit';
  preference.isLocalStoreRequired = true;
  preference.rootDomain = 'vip.ve.atsign.zone';
  return preference;
}
