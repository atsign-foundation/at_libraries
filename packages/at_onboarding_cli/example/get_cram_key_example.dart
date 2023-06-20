import 'package:at_onboarding_cli/src/util/onboarding_util.dart';

Future<void> main() async {
  await OnboardingUtil().requestAuthenticationOtp(
      'your atsign here'); // requires a registered atsign
  String cramKey = await OnboardingUtil().getCramKey('your atsign here',
      'verification code'); // verification code received on the registered email
  print('Your cram key is: $cramKey');
}
