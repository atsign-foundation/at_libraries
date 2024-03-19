import 'package:at_auth/src/enroll/at_enrollment_request.dart';

/// Class for attributes required specifically for new enrollment requests from client.
@Deprecated('Use EnrollmentRequest')
class AtNewEnrollmentRequest extends AtEnrollmentRequest {
  final String _otp;

  AtNewEnrollmentRequest.builder(
      AtNewEnrollmentRequestBuilder atNewEnrollmentRequestBuilder)
      : _otp = atNewEnrollmentRequestBuilder._otp,
        super.builder(atNewEnrollmentRequestBuilder);

  String get otp => _otp;
}

class AtNewEnrollmentRequestBuilder extends AtEnrollmentRequestBuilder {
  late String _otp;

  AtNewEnrollmentRequestBuilder setOtp(String otp) {
    _otp = otp;
    return this;
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds and returns an instance of [AtNewEnrollmentRequest].
  @override
  // ignore: deprecated_member_use_from_same_package
  AtNewEnrollmentRequest build() {
    // ignore: deprecated_member_use_from_same_package
    return AtNewEnrollmentRequest.builder(this);
  }
}
