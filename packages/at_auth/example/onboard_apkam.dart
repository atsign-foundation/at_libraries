import 'package:at_auth/at_auth.dart';

/// dart onboard_apkam.dart <atsign> <cram_secret>
void main(List<String> args) async {
  final atAuth = AtAuthImpl();
  final atSign = args[0];
  final atOnboardingRequest = AtOnboardingRequest(atSign)
    ..rootDomain = 'vip.ve.atsign.zone'
    ..enableEnrollment = true
    ..appName = 'wavi'
    ..deviceName = 'iphone';
  final atOnboardingResponse =
      await atAuth.onboard(atOnboardingRequest, args[1]);
  print('atOnboardingResponse: $atOnboardingResponse');
}
