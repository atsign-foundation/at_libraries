import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/at_onboarding_service.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main(List<String> arguments) async {
  AtSignLogger.root_level = 'finest';
  String atSign = arguments[0];
  OnboardingService onboardingService = OnboardingService(atSign);
  await onboardingService.authenticate();
  await onboardingService.onboard();
}
