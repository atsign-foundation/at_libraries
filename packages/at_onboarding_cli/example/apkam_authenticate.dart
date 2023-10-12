import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main() async {
  // final enrollIdFromServer = '867307c7-53bd-4736-8fe7-1520de58ce78';
  AtSignLogger.root_level = 'finest';
  final atSign = '@alice🛠';
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/murali/.atsign/@alice🛠_key.atKeys'
    ..rootDomain = 'vip.ve.atsign.zone';
  AtOnboardingService? onboardingService = AtOnboardingServiceImpl(
      atSign, atOnboardingPreference);
  await onboardingService.authenticate(); // when authenticating
  // AtLookUp? atLookup = onboardingService.atLookUp;
  // AtClient? client = onboardingService.atClient;
  // print(await client?.getKeys());
  // print(await atLookup?.scan(regex: 'publickey'));
  // await onboardingService.close();
}
