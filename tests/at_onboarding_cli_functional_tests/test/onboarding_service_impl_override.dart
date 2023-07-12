import 'package:at_onboarding_cli/at_onboarding_cli.dart';

class OnboardingServiceImplOverride extends AtOnboardingServiceImpl {
  OnboardingServiceImplOverride(
      atsign, AtOnboardingPreference atOnboardingPreference)
      : super(atsign, atOnboardingPreference);

  @override
  Future<bool> isOnboarded() async {
    return false;
  }
}
