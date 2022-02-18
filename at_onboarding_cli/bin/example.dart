import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    //..qrCodePath = '/home/srie/Desktop/work/at_libraries/at_libraries/at_onboarding_cli/lib/config/download.png'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..hiveStoragePath = 'lib/config/storage'
    ..namespace = 'test'
    ..downloadPath = '~/Downloads/test'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'lib/config/commitLog'
    ..cramSecret = 'b26455a907582760ebf35bc4847de549bc41c24b25c8b1c58d5964f7b4f8a43bc55b0e9a601c9a9657d9a8b8bbc32f88b4e38ffaca03c8710ebae1b14ca9f364';
    //..atKeysFilePath = 'lib/config/@resultingantarmahal7_key.atKeys';

  AtOnboardingServiceImpl onboardingService =
      AtOnboardingServiceImpl('@alice', atOnboardingConfig);

  if (await onboardingService.onboard()) {
    AtLookupImpl? atLookup = onboardingService.getAtLookup();
    print(await atLookup?.update('public:test', 'zzzzzzzz'));
    var keys = await atLookup?.scan();
    print('scan ${keys.toString()}');
    print(await atLookup?.llookup('public:test'));
    //print(await atLookup?.delete(AT_PKAM_PUBLIC_KEY));
    print(await atLookup?.llookup(AT_PKAM_PUBLIC_KEY));
    //AtClient? atClient = onboardingService.atClient;
    //print('\n getAtKeys ${atClient?.getAtKeys().toString()}');
  }
}
