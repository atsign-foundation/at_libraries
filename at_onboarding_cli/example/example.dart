import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  //onboarding preference builder can be used to set onboardingService parameters
  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
        //..qrCodePath = <path to qr code containing cram secret>
        ..hiveStoragePath = 'lib/config/storage'
        ..namespace = 'example'
        ..downloadPath = '/home/srie/Desktop/test_cli'
        ..isLocalStoreRequired = true
        ..commitLogPath = 'lib/config/commitLog'
        ..cramSecret = '<your cram secret>';
        //..atKeysFilePath = <path to .atKeysFile>

  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl('your atsign here', atOnboardingConfig);
  await onboardingService.onboard();
  AtLookUp? atLookup = onboardingService.getAtLookup();
  print(await atLookup?.scan(regex: 'publickey'));
}
