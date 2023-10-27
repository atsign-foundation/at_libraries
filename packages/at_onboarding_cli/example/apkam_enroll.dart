import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main(List<String> args) async {
  AtSignLogger.root_level = 'finer';
  final atSign = args[0];
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'buzz' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = args[1]
    ..appName = 'buzz'
    ..deviceName = 'iphone'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..apkamAuthRetryDurationMins = 1;
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl(atSign, atOnboardingPreference);
  Map<String, String> namespaces = {"buzz": "rw"};
  // run totp:get from enrolled client and pass the otp
  var enrollmentResponse =
      await onboardingService.enroll('buzz', 'iphone', args[2], namespaces);
  print('enrollmentResponse: $enrollmentResponse');
}
