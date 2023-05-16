import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

Future<void> main() async {
  //****************************************************
  // Example for authenticating an atsign
  //onboarding preference builder can be used to set onboardingService parameters
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

  //*****************************************************
  // Example for onboarding an atsign with cram secret
  AtOnboardingPreference onboardingPreference = AtOnboardingPreference()
    ..namespace =
        'your_namespace' // unique identifier that can be used to identify data from your app
    ..cramSecret = '<your cram secret>';
  AtOnboardingService? atOnboardingService =
      AtOnboardingServiceImpl('your atsign here', onboardingPreference);
  await atOnboardingService.onboard(); // when authenticating
  AtLookUp? atLookUp = onboardingService.atLookUp;
  AtClient? atClient = onboardingService.atClient;
  print(atClient?.getKeys());
  print(await atLookUp?.scan(regex: 'publickey'));
  await onboardingService.close();

  //******************************************************
  // Example to fetch cram key using verification code

  await OnboardingUtil().requestAuthenticationOtp(
      'your atsign here'); // requires a registered atsign
  String cramKey = await OnboardingUtil().getCramKey('your atsign here',
      'verification code'); // verification code received on the registered email
  print('Your cram key is: $cramKey');
}
