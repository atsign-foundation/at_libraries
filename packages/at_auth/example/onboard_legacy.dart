import 'package:at_auth/at_auth.dart';

/// dart onboard_legacy.dart <atsign> <cram_secret>
void main(List<String> args) async {
  final atAuth = AtAuthImpl();
  final atSign = args[0];
  final atOnboardingRequest = AtOnboardingRequest(atSign)
    ..rootDomain = 'vip.ve.atsign.zone';
  final atOnboardingResponse =
      await atAuth.onboard(atOnboardingRequest, args[1]);
  print('atOnboardingResponse: $atOnboardingResponse');
}
