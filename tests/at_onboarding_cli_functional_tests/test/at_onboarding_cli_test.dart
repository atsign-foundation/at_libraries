import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_server_status/at_server_status.dart';
import 'package:test/test.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_onboarding_cli/src/activate_cli/activate_cli.dart'
    as activate_cli;

Future<void> main() async {
  AtSignLogger.root_level = 'finer';
  group('Tests to validate authenticate functionality; ', () {

    test('Test using atKeys File', () async {
      String atsign = '@emoji🦄🛠';
      AtOnboardingPreference atOnboardingPreference =
          getPreferences(atsign, false);
      atOnboardingPreference.atKeysFilePath =
          atOnboardingPreference.downloadPath;
      await generateAtKeysFile(atsign, atOnboardingPreference.atKeysFilePath);
      //setting private key to null to ensure that private key is acquired from the atKeysFile
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);
      bool status = await atOnboardingService.authenticate();
      expect(true, status);
    });

    test('test atLookup auth status', () async {
      String atsign = '@emoji🦄🛠';
      AtOnboardingPreference atOnboardingPreference =
          getPreferences(atsign, false);
      atOnboardingPreference.atKeysFilePath =
          atOnboardingPreference.downloadPath;
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, getPreferences(atsign, false));
      await atOnboardingService.authenticate();
      await insertSelfEncKey(await atOnboardingService.getAtClient(), atsign);
      AtLookUp? atLookUp = atOnboardingService.getAtLookup();
      AtKey key = AtKey();
      key.key = 'testKey2';
      await atLookUp?.update(key.key!, 'value2');
      String? response = await atLookUp?.llookup(key.key!);
      expect('data:value2', response);
    });

    test('test atLookup auth status using getAtClient()[deprecated]', () async {
      String atsign = '@emoji🦄🛠';
      AtOnboardingPreference atOnboardingPreference =
          getPreferences(atsign, false);
      atOnboardingPreference.atKeysFilePath =
          atOnboardingPreference.downloadPath;
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, getPreferences(atsign, false));
      await atOnboardingService.authenticate();
      await insertSelfEncKey(await atOnboardingService.getAtClient(), atsign);
      AtLookUp? atLookUp = atOnboardingService.getAtLookup();
      AtKey key = AtKey();
      key.key = 'testKey2';
      await atLookUp?.update(key.key!, 'value2');
      String? response = await atLookUp?.llookup(key.key!);
      expect('data:value2', response);
    });

    test('test atClient authentication using getAtLookup[deprecated]',
        () async {
      String atsign = '@eve🛠';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atsign, getPreferences(atsign, false));
      AtClient? atClient = await onboardingService.getAtClient();
      await insertSelfEncKey(atClient, atsign);
      AtKey key = AtKey();
      key.key = 'testKey3';
      key.namespace = 'wavi';
      await atClient?.put(key, 'value3');
      AtValue? response = await atClient?.get(key);
      expect('value3', response?.value);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('tests to check encryption keys persist into local secondary', () {
    String atsign = '@eve🛠';
    AtOnboardingPreference atOnboardingPreference =
        getPreferences(atsign, false);
    atOnboardingPreference.atKeysFilePath = atOnboardingPreference.downloadPath;
    AtOnboardingService atOnboardingService =
        AtOnboardingServiceImpl(atsign, atOnboardingPreference);
    AtClient? atClient;

    test('test authentication', () async {
      await generateAtKeysFile(atsign, atOnboardingPreference.atKeysFilePath);
      await insertSelfEncKey(atClient, atsign);
      bool status = await atOnboardingService.authenticate();
      atClient = await atOnboardingService.getAtClient();
      expect(true, status);
    });

    test('test pkamPrivateKey on local secondary', () async {
      expect(at_demos.pkamPrivateKeyMap[atsign],
          await atClient?.getLocalSecondary()?.getPrivateKey());
    });

    test('test pkamPublicKey on local secondary', () async {
      expect(at_demos.pkamPublicKeyMap[atsign],
          await atClient?.getLocalSecondary()?.getPublicKey());
    });

    test('test encryptionPrivateKey on local secondary', () async {
      expect(at_demos.encryptionPrivateKeyMap[atsign],
          await atClient?.getLocalSecondary()?.getEncryptionPrivateKey());
    });

    test('test encryptionPublicKey on local secondary', () async {
      String? result =
          await atClient?.getLocalSecondary()?.getEncryptionPublicKey(atsign);
      expect(at_demos.encryptionPublicKeyMap[atsign], result);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('tests for onboard functionality', () {
    String atsign = '@egcovidlab🛠';
    AtOnboardingPreference atOnboardingPreference =
        getPreferences(atsign, true);

    test('test onboarding functionality', () async {
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);
      bool status = await atOnboardingService.onboard();
      expect(true, status);
      atOnboardingPreference.atKeysFilePath =
          atOnboardingPreference.downloadPath;
      bool status2 = await atOnboardingService.authenticate();
      expect(true, status2);
      AtServerStatus atServerStatus = AtStatusImpl(
          rootUrl: atOnboardingPreference.rootDomain,
          rootPort: atOnboardingPreference.rootPort);
      AtStatus atStatus = await atServerStatus.get(atsign);
      expect(atStatus.serverStatus, ServerStatus.activated);
    });

    test('test to validate generated .atKeys file', () async {
      expect(await File(atOnboardingPreference.atKeysFilePath!).exists(), true);
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  group('test activate_cli', () {
    String atsign = '@bob🛠';
    String filePath = '${Directory.current.path}/keys/${atsign}_key.atKeys';

    test('activate using activate_cli', () async {
      List<String> args = [
        '-a',
        atsign,
        '-c',
        at_demos.cramKeyMap[atsign]!,
        '-r',
        'vip.ve.atsign.zone'
      ];
      await activate_cli.main(args);
      expect(await File(filePath).exists(), true);
    });

    test('auth using atKeys file generated from activate_cli', () async {
      AtOnboardingPreference atOnboardingPreference =
          getPreferences(atsign, true);
      atOnboardingPreference.atKeysFilePath = filePath;

      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);
      expect(await onboardingService.authenticate(), true);
    });
  });

  tearDown(() async {
    await tearDownFunc();
  });
}

AtOnboardingPreference getPreferences(String atsign, bool isOnboarding) {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = 'vip.ve.atsign.zone'
    ..isLocalStoreRequired = true
    ..hiveStoragePath = 'storage/hive/client'
    ..commitLogPath = 'storage/hive/client/commit'
    ..privateKey = null
    ..cramSecret = at_demos.cramKeyMap[atsign]
    ..downloadPath = 'storage/keysFile.atKeys';
  if (isOnboarding) {
    atOnboardingPreference.downloadPath = 'storage/';
  }
  return atOnboardingPreference;
}

Future<void> generateAtKeysFile(String atsign, String? filePath) async {
  Map<String, String?> atKeysMap = <String, String?>{
    AuthKeyType.pkamPublicKey: EncryptionUtil.encryptValue(
        at_demos.pkamPublicKeyMap[atsign]!, at_demos.aesKeyMap[atsign]!),
    AuthKeyType.pkamPrivateKey: EncryptionUtil.encryptValue(
        at_demos.pkamPrivateKeyMap[atsign]!, at_demos.aesKeyMap[atsign]!),
    AuthKeyType.encryptionPublicKey: EncryptionUtil.encryptValue(
        at_demos.encryptionPublicKeyMap[atsign]!, at_demos.aesKeyMap[atsign]!),
    AuthKeyType.encryptionPrivateKey: EncryptionUtil.encryptValue(
        at_demos.encryptionPrivateKeyMap[atsign]!, at_demos.aesKeyMap[atsign]!),
    AuthKeyType.selfEncryptionKey: at_demos.aesKeyMap[atsign],
    atsign: at_demos.aesKeyMap[atsign]
  };
  IOSink atKeysFile = File(filePath!).openWrite();
  atKeysFile.write(jsonEncode(atKeysMap));
  await atKeysFile.flush();
  await atKeysFile.close();
}

Future<void> insertSelfEncKey(AtClient? atClient, String atsign) async {
  await atClient
      ?.getLocalSecondary()
      ?.putValue(AT_ENCRYPTION_SELF_KEY, at_demos.aesKeyMap[atsign]!);
  return;
}

Future<void> tearDownFunc() async {
  bool isExists = await Directory('storage/').exists();
  if (isExists) {
    Directory('storage/').deleteSync(recursive: true);
  }
}
