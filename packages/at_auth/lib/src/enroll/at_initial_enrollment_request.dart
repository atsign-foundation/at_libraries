import 'package:at_auth/src/enroll/at_enrollment_request.dart';

/// Class for attributes required specifically for enrollment from the first onboarding client that
/// has enableEnrollment flag set to true from client side in preferences.
/// Default encryption private key and default self encryption keys are encrypted using APKAM symmetric key generated for the onboarding client.
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
