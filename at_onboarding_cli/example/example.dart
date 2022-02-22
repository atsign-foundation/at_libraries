import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    //..qrCodePath = <path to qr code containing cram secret>
    ..qrCodePath = '/home/srie/Desktop/work/at_libraries/at_libraries/at_onboarding_cli/lib/config/qrcode_amateur14.png'
    ..rootDomain = 'root.atsign.org'
    ..rootPort = 64
    ..hiveStoragePath = 'lib/config/storage'
    ..namespace = 'test'
    ..downloadPath = '/home/srie/Desktop/test_cli'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'lib/config/commitLog'
    //..cramSecret = <your cram secret>;
    ;//..atKeysFilePath = 'lib/config/@capitalistfriedchicken_key.atKeys';

  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl('@amateur14', atOnboardingConfig);
  await onboardingService.onboard();
  AtLookUp? atLookup = onboardingService.getAtLookup();
  print(await atLookup?.scan(regex: 'publickey'));
  //print(await atLookup?.lookup('public:publickey'));

}
