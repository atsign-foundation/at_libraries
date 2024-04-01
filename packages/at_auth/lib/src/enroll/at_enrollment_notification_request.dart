import 'package:at_auth/src/enroll/at_enrollment_request.dart';

/// In APKAM approval flow, use this class from a privileged client to set attributes required for enrollment approval.
/// Once a notification is received on the privileged client which can approve enrollment notifications from new devices,
/// use [AtEnrollmentNotificationRequestBuilder] to create [AtEnrollmentNotificationRequest]
@Deprecated('Use EnrollmentServerResponse')
class AtEnrollmentNotificationRequest extends AtEnrollmentRequest {
  final String _encryptedApkamSymmetricKey;

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

  // ignore: deprecated_member_use_from_same_package
  /// Builds and returns an instance of [AtEnrollmentNotificationRequest].
  @override
  // ignore: deprecated_member_use_from_same_package
  AtEnrollmentNotificationRequest build() {
    // ignore: deprecated_member_use_from_same_package
    return AtEnrollmentNotificationRequest.builder(this);
  }
}
