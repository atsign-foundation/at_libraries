import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingConfig atOnboardingConfig = AtOnboardingConfig()
    ..qrCodePath = 'lib/config/download.png'
    ..rootDomain = 'root.atsign.org'
    ..hiveStoragePath = 'lib/config/storage'
    ..namespace = 'test'
    ..downloadPath = '~/Downloads/test'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'lib/config/commitLog';
    //..atKeysFilePath = 'lib/config/@resultingantarmahal7_key.atKeys';

  OnboardingService onboardingService =
      OnboardingService('@almond12typical50donkey', atOnboardingConfig);

  if (await onboardingService.onboard()) {
    AtLookupImpl? atLookup = onboardingService.getAtLookup();
    print(await atLookup?.update('public:test', 'zzzzzzzz'));
    var keys = await atLookup?.scan();
    print('scan ${keys.toString()}');
    print(await atLookup?.delete(AT_PKAM_PUBLIC_KEY));
    print(await atLookup?.llookup(AT_PKAM_PUBLIC_KEY));
    //AtClient? atClient = onboardingService.atClient;
    //print('\n getAtKeys ${atClient?.getAtKeys().toString()}');
  }
}
