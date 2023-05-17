import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

Future<void> main() async {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'your_namespace' // unique identifier that can be used to identify data from your app
    ..cramSecret = '<your cram secret>'
    ..atKeysFilePath = '/home/user/atsign/alice_key.atKeys';
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl('your atsign here', atOnboardingPreference);
  await onboardingService.authenticate(); // when authenticating
  AtLookUp? atLookup = onboardingService.atLookUp;
  AtClient? client = onboardingService.atClient;
  print(client?.getKeys());
  print(await atLookup?.scan(regex: 'publickey'));
  await onboardingService.close();
}
