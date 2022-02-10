import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';

void main() async {
  AtOnboardingConfig atOnboardingConfig = AtOnboardingConfig()
    ..qrCodePath = 'at_onboarding_cli/lib/config/qr.png'
    ..atKeysFilePath = 'lib/config/@resultingantarmahal7_key.atKeys';
  OnboardingService onboardingService =
      OnboardingService('@resultingantarmahal7', atOnboardingConfig);
  onboardingService.authenticate();
  AtLookupImpl atLookup = onboardingService.getAtLookup();
  var keys = await atLookup.scan(auth: false);
  print('scan ${keys.toString()}');
}
