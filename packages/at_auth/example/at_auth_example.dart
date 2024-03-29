import 'package:at_auth/at_auth.dart';

/// dart at_auth_example.dart <atsign> <path_to_atkeys_file>
void main(List<String> args) async {
  final atAuth = AtAuthImpl();
  final atSign = args[0];
  final atAuthRequest = AtAuthRequest(atSign)
    ..rootDomain = 'vip.ve.atsign.zone'
    ..atKeysFilePath = args[1];
  final atAuthResponse = await atAuth.authenticate(atAuthRequest);
  print('atAuthResponse: $atAuthResponse');
}
