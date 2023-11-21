import 'package:at_enrollment_cli/at_enrollment_cli.dart';
import 'package:at_enrollment_cli/onboard_atsign.dart';
import 'package:at_utils/at_logger.dart';

void main(List<String> arguments) async {
  AtSignLogger.root_level = 'severe';
  OnboardAtSign onboardAtSign = OnboardAtSign();
  AtSignRegistrationResponse registerAtSignResponse =
      await onboardAtSign.registerAtSign('sitaram@atsign.com');
  await onboardAtSign.activateAtSign(registerAtSignResponse);

  AtEnrollmentService atEnrollmentService =
      AtEnrollmentService(registerAtSignResponse.atSign);
  await atEnrollmentService.authenticate(
      '/home/sitaram/.atsign/keys/${registerAtSignResponse.atSign}_key.atKeys');
  await atEnrollmentService.fetchOTP();
  await atEnrollmentService.initMonitor();
}
