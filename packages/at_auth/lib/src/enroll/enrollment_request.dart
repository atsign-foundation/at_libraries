import 'package:at_auth/src/enroll/base_enrollment_request.dart';

class EnrollmentRequest extends BaseEnrollmentRequest {
  Map<String, String> namespaces;
  String? encryptedAPKAMSymmetricKey;
  String otp;

  EnrollmentRequest(
      {required super.appName,
      required super.deviceName,
      super.apkamPublicKey,
      required this.otp,
      required this.namespaces,
      this.encryptedAPKAMSymmetricKey});
}
