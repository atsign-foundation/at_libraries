import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

Future<void> main() async {
  //onboarding preference builder can be used to set onboardingService parameters
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..qrCodePath = 'storage/qr_code.png'
    ..hiveStoragePath = 'storage/hive'
    ..namespace = 'example'
    ..downloadPath = 'storage/files'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'storage/commitLog'
    ..cramSecret = '<your cram secret>'
    ..privateKey = '<your private key here>'
    ..atKeysFilePath = 'storage/alice_key.atKeys';
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl('your atsign here', atOnboardingPreference);
  await onboardingService.onboard();
  AtLookUp? atLookup = onboardingService.atLookUp;
  print(await atLookup?.scan(regex: 'publickey'));
  await onboardingService.close();
  //free the object after it's used and no longer required
  onboardingService = null;
}
