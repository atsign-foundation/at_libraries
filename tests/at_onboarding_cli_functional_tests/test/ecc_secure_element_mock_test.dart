import 'dart:convert';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:test/test.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'at_chops_secure_element_mock.dart';

/// Usage: dart main.dart <cram_secret>
Future<void> main() async {
  AtSignLogger.root_level = 'FINER';
  var logger = AtSignLogger('OnboardSecureElement');

  final atSign = '@bob🛠';
  test('Test auth functionality', () async {
    AtOnboardingPreference preference = getPreferences(atSign);
    AtOnboardingService onboardingService =
        AtOnboardingServiceImpl(atSign, preference);
    // create empty keys in atchops. Encryption key pair will be set later on after generation
    final atChopsImpl =
        AtChopsSecureElementMock(AtChopsKeys.create(null, null));
    onboardingService.atChops = atChopsImpl;
    atChopsImpl.init();
    logger.info('calling onboard');
    bool isOnboarded = await onboardingService.onboard();
    expect(isOnboarded, true);
    logger.info('onboard done');
    logger.info('calling auth');

    bool status = await onboardingService.authenticate();
    logger.info('auth done');
    expect(status, true);

    // update a key
    AtClient? atClient = await onboardingService.getAtClient();
    await insertSelfEncKey(atClient, atSign,
        selfEncryptionKey:
            await getSelfEncryptionKey(preference.atKeysFilePath!));
    AtKey key = AtKey();
    key.key = 'securedKey';
    key.namespace = 'wavi';
    var putResult = await atClient?.put(key, 'securedvalue');
    expect(putResult, true);
    AtValue? response = await atClient?.get(key);
    expect('securedvalue', response?.value);
    var deleteResponse = await atClient?.delete(key);
    expect(deleteResponse, true);
  });

  tearDown(() async {
    await tearDownFunc();
  });
}

AtOnboardingPreference getPreferences(String atsign) {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..hiveStoragePath =
        'storage/hive'
    ..namespace = 'wavi'
    ..downloadPath =
        'storage/files'
    ..isLocalStoreRequired = true
    ..commitLogPath =
        'storage/commitLog'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..fetchOfflineNotifications = true
    ..atKeysFilePath =
        'storage/files/@bob🛠_key.atKeys'
    ..useAtChops = true
    ..signingAlgoType = SigningAlgoType.ecc_secp256r1
    ..hashingAlgoType = HashingAlgoType.sha256
    ..authMode = PkamAuthMode.sim
    ..publicKeyId = '3023020'
    ..cramSecret = at_demos.cramKeyMap[atsign]
    ..skipSync = true;

  return atOnboardingPreference;
}

Future<String?> getSelfEncryptionKey(String atKeysFilePath) async {
  String atAuthData = await File(atKeysFilePath).readAsString();
  Map<String, String> jsonData = <String, String>{};
  json.decode(atAuthData).forEach((String key, dynamic value) {
    jsonData[key] = value.toString();
  });
  return jsonData[AT_ENCRYPTION_SELF_KEY];
}

Future<void> insertSelfEncKey(AtClient? atClient, String atsign,
    {String? selfEncryptionKey}) async {
  await atClient?.getLocalSecondary()?.putValue(
      AT_ENCRYPTION_SELF_KEY, selfEncryptionKey ?? at_demos.aesKeyMap[atsign]!);
  return;
}

Future<void> tearDownFunc() async {
  bool isExists = await Directory('storage/').exists();
  if (isExists) {
    Directory('storage/').deleteSync(recursive: true);
  }
}
