import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  OnboardingService onboardingService = OnboardingService('resultingantarmahal7');
  onboardingService.authenticate();
  AtLookupImpl atLookup = onboardingService.getAtLookup();
  var keys = await atLookup.scan(auth: false);
  print('scan ${keys.toString()}');
}
