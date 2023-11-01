import 'package:at_auth/at_auth.dart';

class AtAuthResponse {
  String atSign;
  bool isSuccessful = false;
  String? enrollmentId;
  AtAuthKeys? atAuthKeys;

  AtAuthResponse(this.atSign);

  @override
  String toString() {
    return 'AtAuthResponse{atSign: $atSign, enrollmentId: $enrollmentId, isSuccessful: $isSuccessful}';
  }
}
