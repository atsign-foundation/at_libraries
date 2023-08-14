import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main() async {
  AtSignLogger.root_level = 'finer';
  final atSign = '@alice';
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'buzz' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = '/home/user/atsign/alice_buzzkey.atKeys'
    ..appName = 'buzz'
    ..deviceName = 'iphone'
    ..rootDomain = 'vip.ve.atsign.zone';
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl(atSign, atOnboardingPreference);
  Map<String, String> namespaces = {"buzz": "rw"};
  // run totp:get from enrolled client and pass the otp
  var enrollmentResponse =
      await onboardingService.enroll('buzz', 'iphone', "068881", namespaces);
  print('enrollmentResponse: $enrollmentResponse');
}
