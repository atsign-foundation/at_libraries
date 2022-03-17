import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:test/test.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:at_demo_data/at_demo_data.dart' as at_demos;

void main() {
  AtSignLogger.root_level = 'FINEST';
  group('Tests to validate authenticate functionality', () {
    test('test authentication using private key', () async {
      String atsign = '@bob🛠';
      AtOnboardingService onboardingService =
          AtOnboardingServiceImpl(atsign, getPreferences(atsign));
      bool authStatus = await onboardingService.authenticate();
      await insertSelfEncKey(await onboardingService.getAtClient(), atsign);
      expect(true, authStatus);
    });

    test('Test using atKeys File', () async {
      var atsign = '@alice🛠';
      AtOnboardingPreference atOnboardingPreference = getPreferences(atsign);
      atOnboardingPreference.atKeysFilePath =
          atOnboardingPreference.downloadPath;
      generateAtKeysFile(atsign, atOnboardingPreference.atKeysFilePath);
      //setting private key to null to ensure that private key is acquired from the atKeysFile
      atOnboardingPreference.privateKey = null;
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);
      bool status = await atOnboardingService.authenticate();
      expect(true, status);
    });
  });

  test('test atLookup auth status', () async {
    var atsign = '@alice🛠';
    AtOnboardingPreference atOnboardingPreference = getPreferences(atsign);
    atOnboardingPreference.atKeysFilePath = atOnboardingPreference.downloadPath;
    //setting private key to null to ensure that private key is acquired from the atKeysFile
    atOnboardingPreference.privateKey = null;
    AtOnboardingService atOnboardingService =
        AtOnboardingServiceImpl(atsign, getPreferences(atsign));
    await atOnboardingService.authenticate();
    AtLookUp? atLookUp = atOnboardingService.getAtLookup();
    AtKey key = AtKey();
    key.key = 'testKey2';
    await atLookUp?.update(key.key!, 'value2');
    var response = await atLookUp?.llookup(key.key!);
    print(response);
    expect('data:value2', response);
  });

  test('test atClient authentication', () async {
    var atsign = '@eve🛠';
    AtOnboardingService onboardingService =
        AtOnboardingServiceImpl(atsign, getPreferences(atsign));
    AtClient? atClient = await onboardingService.getAtClient();
    await insertSelfEncKey(atClient, atsign);
    AtKey key = AtKey();
    key.key = 'testKey3';
    await atClient?.put(key, 'value3');
    var response = await atClient?.get(key);
    expect('value3', response?.value);
  });

  group('tests to check encryption keys persist into local secondary', () {
    var atsign = '@eve🛠';
    AtOnboardingPreference atOnboardingPreference = getPreferences(atsign);
    atOnboardingPreference.atKeysFilePath = atOnboardingPreference.downloadPath;
    AtOnboardingService atOnboardingService =
        AtOnboardingServiceImpl(atsign, atOnboardingPreference);
    AtClient? atClient;

    test('test authentication', () async {
      await generateAtKeysFile(atsign, atOnboardingPreference.atKeysFilePath);
      await insertSelfEncKey(atClient, atsign);
      var status = await atOnboardingService.authenticate();
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
      expect(at_demos.encryptionPublicKeyMap[atsign],
          await atClient?.getLocalSecondary()?.getEncryptionPublicKey(atsign));
    });
  });

  group('tests for onboard functionality', () {
    var atsign = '@alice🛠';
    AtOnboardingPreference atOnboardingPreference = getPreferences(atsign);
    test('test onboarding functionality', () async {
      AtOnboardingService atOnboardingService =
          AtOnboardingServiceImpl(atsign, atOnboardingPreference);
      var status = await atOnboardingService.onboard();
      expect(true, status);
      expect(true, File(atOnboardingPreference.downloadPath!).exists());
    });
  });

  tearDown(() async => await tearDownFunc());
}

AtOnboardingPreference getPreferences(String atsign) {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = 'vip.ve.atsign.zone'
    ..isLocalStoreRequired = true
    ..hiveStoragePath = 'storage/hive/client'
    ..commitLogPath = 'storage/hive/client/commit'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..privateKey = at_demos.pkamPrivateKeyMap[atsign]
    ..cramSecret = at_demos.cramKeyMap[atsign]
    ..downloadPath = 'storage/keysFile_$atsign.atKeys';
  return atOnboardingPreference;
}

Future<void> generateAtKeysFile(atsign, filePath) async {
  Map atKeysMap = {
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
  print(EncryptionUtil.decryptValue(atKeysMap[AuthKeyType.encryptionPrivateKey],
      atKeysMap[AuthKeyType.selfEncryptionKey]));
  IOSink atKeysFile = File(filePath).openWrite();
  atKeysFile.write(jsonEncode(atKeysMap));
  await atKeysFile.flush();
  await atKeysFile.close();
}

Future<bool> insertSelfEncKey(atClient, atsign) async {
  var response = await atClient
      ?.getLocalSecondary()
      ?.putValue(AT_ENCRYPTION_SELF_KEY, at_demos.aesKeyMap![atsign]!);
  return response;
}

Future<void> tearDownFunc() async {
  var isExists = await Directory('test/storage/').exists();
  print('-------------------------$isExists');
  if (isExists) {
    Directory('test/storage/').deleteSync(recursive: true);
  }
}
