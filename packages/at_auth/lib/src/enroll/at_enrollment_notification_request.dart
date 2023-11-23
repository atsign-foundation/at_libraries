import 'package:at_auth/src/enroll/at_enrollment_request.dart';

class AtEnrollmentNotificationRequest extends AtEnrollmentRequest {
  String _encryptedApkamSymmetricKey;

  String get encryptedApkamSymmetricKey => _encryptedApkamSymmetricKey;

  AtEnrollmentNotificationRequest.builder(
      AtEnrollmentNotificationRequestBuilder
          atEnrollmentNotificationRequestBuilder)
      : _encryptedApkamSymmetricKey =
            atEnrollmentNotificationRequestBuilder._encryptedApkamSymmetricKey,
        super.builder(atEnrollmentNotificationRequestBuilder);
}

class AtEnrollmentNotificationRequestBuilder
    extends AtEnrollmentRequestBuilder {
  late String _encryptedApkamSymmetricKey;

  AtEnrollmentNotificationRequestBuilder setEncryptedApkamSymmetricKey(
      String encryptedApkamSymmetricKey) {
    _encryptedApkamSymmetricKey = encryptedApkamSymmetricKey;
    return this;
  }

  /// Builds and returns an instance of [AtEnrollmentNotificationRequest].
  AtEnrollmentNotificationRequest build() {
    return AtEnrollmentNotificationRequest.builder(this);
  }
}
