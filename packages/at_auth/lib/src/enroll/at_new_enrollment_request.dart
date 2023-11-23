import 'package:at_auth/src/enroll/at_enrollment_request.dart';

class AtNewEnrollmentRequest extends AtEnrollmentRequest {
  String _otp;

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

  /// Builds and returns an instance of [AtInitialEnrollmentRequest].
  AtNewEnrollmentRequest build() {
    return AtNewEnrollmentRequest.builder(this);
  }
}
