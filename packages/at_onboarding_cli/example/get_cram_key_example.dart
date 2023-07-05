import 'package:at_onboarding_cli/src/register_cli/registrar_api_util.dart';

Future<void> main() async {
  await RegistrarApiUtil().requestAuthenticationOtp(
      'your atsign here'); // requires a registered atsign
  String cramKey = await RegistrarApiUtil().getCramKey('your atsign here',
      'verification code'); // verification code received on the registered email
  print('Your cram key is: $cramKey');
}
