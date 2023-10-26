import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

Future<void> main() async {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/murali/atsign/alice_key.atKeys'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..hiveStoragePath = 'home/murali/atsign/@alice/storage/hive'
    ..commitLogPath = 'home/murali/atsign/@alice/storage/commitLog';
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl('@alice', atOnboardingPreference);
  await onboardingService.authenticate(); // when authenticating
  AtClient? client = onboardingService.atClient;
  print(await client?.getKeys());
  // print(await atLookup?.scan(regex: 'publickey'));
  await onboardingService.close();
}
