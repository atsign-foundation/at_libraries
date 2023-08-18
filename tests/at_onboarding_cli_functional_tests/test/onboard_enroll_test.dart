import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';

String atSign = '@alice';
var pkamPublicKey;
var pkamPrivateKey;
var encryptionPublicKey;
var encryptionPrivateKey;
var selfEncryptionKey;
void main() {
  AtSignLogger.root_level = 'finest';
  group('A group of tests to assert on authenticate functionality', () {
    test('A test to verify authentication and enroll request', () async {
      // First time authentication using the onboard()
      AtOnboardingPreference preference = getPreferenceForAuth(atSign);
      AtOnboardingService? onboardingService =
          AtOnboardingServiceImpl(atSign, preference);
      bool status = await onboardingService.onboard();
      expect(status, true);
      getAtKeys();
      print('pkam public key : $pkamPublicKey');
      preference.privateKey = pkamPrivateKey;
      await onboardingService.authenticate();
      AtClient? atClient = await onboardingService.atClient;
      // run totp:get from enrolled client and pass the otp
      String? totp = await atClient!
          .getRemoteSecondary()!
          .executeCommand('totp:get\n', auth: true);
      totp = totp!.replaceFirst('data:', '');
      totp = totp.trim();
      Map<String, String> namespaces = {"buzz": "rw"};
      AtOnboardingPreference enrollPreference = getPreferenceForEnroll(atSign);
      onboardingService = AtOnboardingServiceImpl(atSign, enrollPreference);
      await onboardingService.enroll('buzz', 'iphone', totp, namespaces);

      // once enroll request is successful, atkeys should be created
      // assert that the keys file is created
      expect(await File(enrollPreference.atKeysFilePath!).exists(), true);
      // check the authentication with the newly generated auth file
      //  TODO needs an enrollment ID of the above enrollment request
      // await onboardingService.authenticate(enrollmentId: '');
    }, timeout: Timeout(Duration(minutes: 5)));
  });
}

AtOnboardingPreference getPreferenceForAuth(String atSign) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = 'vip.ve.atsign.zone'
    ..isLocalStoreRequired = true
    ..hiveStoragePath = 'storage/hive/client'
    ..commitLogPath = 'storage/hive/client/commit'
    ..cramSecret = at_demos.cramKeyMap[atSign]
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/shaikirfan/.atsign/keys/@alice_key.atKeys'
    ..appName = 'wavi'
    ..deviceName = 'pixel'
    ..rootDomain = 'vip.ve.atsign.zone';

  return atOnboardingPreference;
}

AtOnboardingPreference getPreferenceForEnroll(String atSign) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'buzz' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/shaikirfan/.atsign/keys/@alice_buzzkey.atKeys'
    ..appName = 'buzz'
    ..deviceName = 'iphone'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..apkamAuthRetryDurationMins = 1;
  return atOnboardingPreference;
}

Future<void> getAtKeys() async {
  AtOnboardingPreference preference = getPreferenceForAuth(atSign);
  String? filePath = preference.atKeysFilePath;
  var fileContents = File(filePath!).readAsStringSync();
  var keysJSON = json.decode(fileContents);
  selfEncryptionKey = keysJSON['selfEncryptionKey'];

  pkamPublicKey = EncryptionUtil.decryptValue(
      keysJSON['aesPkamPublicKey'], selfEncryptionKey);
  pkamPrivateKey = EncryptionUtil.decryptValue(
      keysJSON['aesPkamPrivateKey'], selfEncryptionKey);
  encryptionPublicKey = EncryptionUtil.decryptValue(
      keysJSON['aesEncryptPublicKey'], selfEncryptionKey);
  encryptionPrivateKey = EncryptionUtil.decryptValue(
      keysJSON['aesEncryptPrivateKey'], selfEncryptionKey);
}
