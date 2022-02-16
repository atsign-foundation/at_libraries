import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingConfig atOnboardingConfig = AtOnboardingConfig()
    ..qrCodePath = 'at_onboarding_cli/lib/config/qr.png'
    ..atKeysFilePath = 'lib/config/@resultingantarmahal7_key.atKeys';

  OnboardingService onboardingService =
      OnboardingService('@resultingantarmahal7', atOnboardingConfig);

  var atClientPref = AtClientPreference()
    ..rootDomain = 'root.atsign.org'
    ..hiveStoragePath = '~/Documents/storage/hive'
    ..namespace = 'test'
    ..downloadPath = '~/Downloads/test';

  await onboardingService.authenticate(atClientPreference: atClientPref);
  AtLookupImpl? atLookup = onboardingService.getAtLookup();
  var keys = await atLookup?.scan(auth: false);
  print('scan ${keys.toString()}');
  AtClient? atClient = onboardingService.atClient;
  print('\n getAtKeys ${atClient?.getAtKeys()}');
}
