import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/activate_cli/activate_cli.dart'
    as activate_cli;
import 'package:at_server_status/at_server_status.dart';
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';

final String atKeysFilePath = '${Platform.environment['HOME']}/.atsign/keys';

void main() {
  AtSignLogger.root_level = 'finest';
  group('A group of tests to assert on authenticate functionality', () {
    test('A test to verify authentication is successful with .atKeys file',
        () async {
      // Intentionally '@' is not prefixed.
      // AtOnboardingServiceImpl call's fixAtSign which prefixes '@'
      String atSign = 'alice🛠';
      AtOnboardingPreference preference = getPreferences(atSign);
      await generateAtKeysFile(atSign, preference.atKeysFilePath!);
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atSign, preference);
      bool status = await atOnboardingService.authenticate();
      expect(true, status);
    });

    test(
        'A test to verify update and llookup verbs with authenticated atLookup instance',
        () async {
      String atSign = '@alice🛠';
      AtOnboardingPreference preference = getPreferences(atSign);
      await generateAtKeysFile(atSign, preference.atKeysFilePath!);
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atSign, preference);
      await atOnboardingService.authenticate();
      AtLookUp? atLookUp = atOnboardingService.atLookUp;
      AtKey key = AtKey();
      key.key = 'testKey1';
      await atLookUp?.update(key.key!, 'value1');
      String? response = await atLookUp?.llookup(key.key!);
      expect('data:value1', response);
    });

    test(
        'A test to authenticate and atSign and invoke AtClient put and get methods',
        () async {
      String atSign = '@eve🛠';
      AtOnboardingPreference preference = getPreferences(atSign);
      await generateAtKeysFile(atSign, preference.atKeysFilePath!);
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, preference);
      await onboardingService.authenticate();
      AtClient? atClient = await onboardingService.atClient;
      AtKey key = AtKey();
      key.key = 'testKey3';
      key.namespace = 'wavi';
      await atClient?.put(key, 'value3');
      AtValue? response = await atClient?.get(key);
      expect('value3', response?.value);
    });

    test('A test to verify atKeysFilePath is set when null is provided',
        () async {
      String atSign = '@eve🛠';
      AtOnboardingPreference preference = getPreferences(atSign);
      preference.atKeysFilePath = null;
      AtOnboardingServiceImpl(atSign, preference);
      expect(preference.atKeysFilePath, '$atKeysFilePath/${atSign}_key.atKeys');
    });
    tearDown(() async {
      await tearDownFunc();
    });
  });

  group(
      'A group of tests to assert encryption keys persist into local secondary',
      () {
    String atSign = '@eve🛠'.trim();
    AtOnboardingPreference atOnboardingPreference = getPreferences(atSign);
    AtOnboardingService atOnboardingService =
        AtOnboardingServiceImpl(atSign, atOnboardingPreference);
    AtClient? atClient;

    test(
        'A test to authenticate atSign and verify PKAM keys and encryption keys are updated to local secondary',
        () async {
      await generateAtKeysFile(atSign, atOnboardingPreference.atKeysFilePath!);
      bool status = await atOnboardingService.authenticate();
      atClient = await atOnboardingService.atClient;
      expect(true, status);

      expect(at_demos.pkamPrivateKeyMap[atSign],
          await atClient?.getLocalSecondary()?.getPrivateKey());

      expect(at_demos.pkamPublicKeyMap[atSign],
          await atClient?.getLocalSecondary()?.getPublicKey());

      expect(at_demos.encryptionPrivateKeyMap[atSign],
          await atClient?.getLocalSecondary()?.getEncryptionPrivateKey());

      String? encryptionPublicKey =
          await atClient?.getLocalSecondary()?.getEncryptionPublicKey(atSign);
      expect(at_demos.encryptionPublicKeyMap[atSign], encryptionPublicKey);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('A group of tests to verify onboard functionality', () {
    String atSign = '@egcovidlab🛠';
    AtOnboardingPreference atOnboardingPreference = getPreferences(atSign);

    test(
        'A test to verify atSign is onboarded and .atKeys file is generated successfully',
        () async {
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atSign, atOnboardingPreference);
      bool status = await atOnboardingService.onboard();
      expect(true, status);
      bool status2 = await atOnboardingService.authenticate();
      expect(true, status2);
      AtServerStatus atServerStatus = AtStatusImpl(
          rootUrl: atOnboardingPreference.rootDomain,
          rootPort: atOnboardingPreference.rootPort);
      AtStatus atStatus = await atServerStatus.get(atSign);
      expect(atStatus.serverStatus, ServerStatus.activated);

      /// Assert .atKeys file is generated for the atSign
      expect(await File(atOnboardingPreference.atKeysFilePath!).exists(), true);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('A group of tests to verify activate_cli', () {
    String atSign = '@colin🛠';
    test(
        'A test to verify atSign is activated and .atKeys file is generated using activate_cli',
        () async {
      List<String> args = [
        '-a',
        atSign,
        '-c',
        at_demos.cramKeyMap[atSign]!,
        '-r',
        'vip.ve.atsign.zone'
      ];
      await activate_cli.main(args);
      expect(await File('$atKeysFilePath/${atSign}_key.atKeys').exists(), true);

      // Authenticate atSign with the .atKeys file generated via the activate_cli tool.
      AtOnboardingPreference atOnboardingPreference = getPreferences(atSign);
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atSign, atOnboardingPreference);
      expect(await onboardingService.authenticate(), true);
    });

    tearDownAll(() async {
      await tearDownFunc();
    });
  });
}

AtOnboardingPreference getPreferences(String atSign) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = 'vip.ve.atsign.zone'
    ..isLocalStoreRequired = true
    ..hiveStoragePath = 'storage/hive/client'
    ..commitLogPath = 'storage/hive/client/commit'
    ..privateKey = null
    ..cramSecret = at_demos.cramKeyMap[atSign]
    ..atKeysFilePath = '$atKeysFilePath/${atSign}_key.atKeys'
    ..downloadPath = atKeysFilePath;

  return atOnboardingPreference;
}

Future<void> generateAtKeysFile(String atSign, String filePath) async {
  atSign = AtUtils.fixAtSign(atSign);
  Map<String, String?> atKeysMap = <String, String?>{
    AuthKeyType.pkamPublicKey: EncryptionUtil.encryptValue(
        at_demos.pkamPublicKeyMap[atSign]!, at_demos.aesKeyMap[atSign]!),
    AuthKeyType.pkamPrivateKey: EncryptionUtil.encryptValue(
        at_demos.pkamPrivateKeyMap[atSign]!, at_demos.aesKeyMap[atSign]!),
    AuthKeyType.encryptionPublicKey: EncryptionUtil.encryptValue(
        at_demos.encryptionPublicKeyMap[atSign]!, at_demos.aesKeyMap[atSign]!),
    AuthKeyType.encryptionPrivateKey: EncryptionUtil.encryptValue(
        at_demos.encryptionPrivateKeyMap[atSign]!, at_demos.aesKeyMap[atSign]!),
    AuthKeyType.selfEncryptionKey: at_demos.aesKeyMap[atSign],
    atSign: at_demos.aesKeyMap[atSign]
  };

  File file = File(filePath);
  if (!(file.existsSync())) {
    file = await file.create(recursive: true);
  }
  var atKeysFile = await file.open(mode: FileMode.write);
  atKeysFile.writeStringSync(jsonEncode(atKeysMap));
  await atKeysFile.close();
}

Future<void> tearDownFunc() async {
  bool isExists = await Directory('storage/').exists();
  if (isExists) {
    Directory('storage/').deleteSync(recursive: true);
  }
}
