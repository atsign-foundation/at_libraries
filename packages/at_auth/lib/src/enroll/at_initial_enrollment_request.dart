import 'package:at_auth/src/enroll/at_enrollment_request.dart';

class AtInitialEnrollmentRequest extends AtEnrollmentRequest {
  final String _encryptedDefaultEncryptionPrivateKey;
  final String _encryptedDefaultSelfEncryptionKey;

  AtInitialEnrollmentRequest.builder(
      AtInitialEnrollmentRequestBuilder atInitialEnrollmentRequestBuilder)
      : _encryptedDefaultEncryptionPrivateKey =
            atInitialEnrollmentRequestBuilder
                ._encryptedDefaultEncryptionPrivateKey,
        _encryptedDefaultSelfEncryptionKey = atInitialEnrollmentRequestBuilder
            ._encryptedDefaultSelfEncryptionKey,
        super.builder(atInitialEnrollmentRequestBuilder);

  String get encryptedDefaultEncryptionPrivateKey =>
      _encryptedDefaultEncryptionPrivateKey;

  String get encryptedDefaultSelfEncryptionKey =>
      _encryptedDefaultSelfEncryptionKey;
}

class AtInitialEnrollmentRequestBuilder extends AtEnrollmentRequestBuilder {
  late String _encryptedDefaultEncryptionPrivateKey;
  late String _encryptedDefaultSelfEncryptionKey;
  AtEnrollmentRequestBuilder setEncryptedDefaultEncryptionPrivateKey(
      String encryptedDefaultEncryptionPrivateKey) {
    _encryptedDefaultEncryptionPrivateKey =
        encryptedDefaultEncryptionPrivateKey;
    return this;
  }

  AtEnrollmentRequestBuilder setEncryptedDefaultSelfEncryptionKey(
      String encryptedDefaultSelfEncryptionKey) {
    _encryptedDefaultSelfEncryptionKey = encryptedDefaultSelfEncryptionKey;
    return this;
  }

  /// Builds and returns an instance of [AtInitialEnrollmentRequest].
  AtInitialEnrollmentRequest build() {
    return AtInitialEnrollmentRequest.builder(this);
  }
}
