import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    //..qrCodePath = '/home/srie/Desktop/work/at_libraries/at_libraries/at_onboarding_cli/lib/config/download.png'
    ..rootDomain = 'root.atsign.org'
    ..rootPort = 64
    ..hiveStoragePath = 'lib/config/storage'
    ..namespace = 'test'
    ..downloadPath = '/home/srie/Desktop/test_cli'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'lib/config/commitLog'
    //..cramSecret = 'b26455a907582760ebf35bc4847de549bc41c24b25c8b1c58d5964f7b4f8a43bc55b0e9a601c9a9657d9a8b8bbc32f88b4e38ffaca03c8710ebae1b14ca9f364';
    ..atKeysFilePath = 'lib/config/@capitalistfriedchicken_key.atKeys';

  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl('@capitalistfriedchicken', atOnboardingConfig);
  await onboardingService.authenticate();
  var atLookup = onboardingService.getAtlookup();
  print(await atLookup?.scan(auth: false));
  print(AT_ENCRYPTION_PUBLIC_KEY);
  print(await atLookup?.llookup('public:publickey@capital'));

}
