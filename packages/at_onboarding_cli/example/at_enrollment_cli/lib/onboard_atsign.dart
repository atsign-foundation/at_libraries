import 'dart:io';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/util/onboarding_util.dart';
import 'package:at_commons/at_commons.dart';

class OnboardAtSign {
  String rootServer = 'root.atsign.org';
  String registrarUrl = 'my.atsign.com';

  OnboardingUtil onboardingUtil = OnboardingUtil();

  Future<AtSignRegistrationResponse> registerAtSign(String email) async {
    // 1. Fetch a free atSign
    stdout
        .writeln('[Information] Getting your randomly generated free atSign…');
    String atSign = (await onboardingUtil.getFreeAtSigns())[0];
    stdout.writeln('[Information] Your new atSign is @$atSign');
    // 2. Register the new atSign to the email provided by the user
    bool isAtSignRegistered =
        await onboardingUtil.registerAtSign(atSign, email);

    if (isAtSignRegistered == false) {
      throw AtException('Failed to register $atSign to the email: $email');
    }
    stdout.writeln(
        '[Information] Your new atSign @$atSign is successfully registered to the given email address');
    stdout.writeln(
        '[Action Required] Enter your verification code: (verification code is not case-sensitive)');
    String otp = stdin.readLineSync()!.toUpperCase();
    // validateOtp return "atSign:cramSecret". Trim the atSign and set CRAM secret only.
    String cramSecret =
        (await onboardingUtil.validateOtp(atSign, email, otp)).split(':')[1];
    return AtSignRegistrationResponse('@$atSign', cramSecret);
  }

  Future<bool> activateAtSign(
      AtSignRegistrationResponse registerAtSignResponse) async {
    AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
      ..rootDomain = rootServer
      ..registrarUrl = registrarUrl
      ..cramSecret = registerAtSignResponse.cramSecret;
    //onboard the atSign
    AtOnboardingService atOnboardingService = AtOnboardingServiceImpl(
        registerAtSignResponse.atSign, atOnboardingPreference);
    stdout.writeln(
        '[Information] Activating your atSign. This may take up to 2 minutes.');
    try {
      return await atOnboardingService.onboard();
    } on AtException catch (e) {
      stderr.writeln(
          'Failed to activate the atSign: ${registerAtSignResponse.atSign} caused by ${e.message}');
    }
    return false;
  }
}

class AtSignRegistrationResponse {
  String atSign;
  String cramSecret;

  AtSignRegistrationResponse(this.atSign, this.cramSecret);
}
