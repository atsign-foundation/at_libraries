import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

Future<void> main() async {
  final enrollIdFromServer = '867307c7-53bd-4736-8fe7-1520de58ce78';
  final atSign = '@alice';
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'buzz' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/user/atsign/alice_buzzkey.atKeys'
    ..rootDomain = 'vip.ve.atsign.zone';
  AtOnboardingService? onboardingService = AtOnboardingServiceImpl(
      atSign, atOnboardingPreference,
      enrollmentId: enrollIdFromServer);
  await onboardingService.authenticate(
      enrollmentId: enrollIdFromServer); // when authenticating
  AtLookUp? atLookup = onboardingService.atLookUp;
  AtClient? client = onboardingService.atClient;
  print(await client?.getKeys());
  print(await atLookup?.scan(regex: 'publickey'));
  await onboardingService.close();
}
