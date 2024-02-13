import 'package:at_auth/src/enroll/base_enrollment_request.dart';

//Use First.

class InitialEnrollmentRequest extends BaseEnrollmentRequest {
  String encryptedDefaultEncryptionPrivateKey;
  String encryptedDefaultSelfEncryptionKey;

  InitialEnrollmentRequest(
      {required super.appName,
      required super.deviceName,
      required super.apkamPublicKey,
      required this.encryptedDefaultEncryptionPrivateKey,
      required this.encryptedDefaultSelfEncryptionKey});
}
