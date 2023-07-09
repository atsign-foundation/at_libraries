import 'package:at_onboarding_cli/at_onboarding_cli.dart';

class TestOnboardingServiceImpl extends AtOnboardingServiceImpl {
  TestOnboardingServiceImpl(
      atsign, AtOnboardingPreference atOnboardingPreference)
      : super(atsign, atOnboardingPreference);

  @override
  Future<bool> isOnboarded() async {
    return false;
  }
}
