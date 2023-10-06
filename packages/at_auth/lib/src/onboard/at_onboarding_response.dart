import 'package:at_auth/src/keys/at_security_keys.dart';

class AtOnboardingResponse {
  String atSign;
  String? enrollmentId;
  AtOnboardingResponse(this.atSign);
  bool? isSuccessful;
  AtSecurityKeys? atSecurityKeys;
}
