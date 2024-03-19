import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_request.dart';

/// Class for attributes required specifically for enrollment from the first onboarding client that
/// has enableEnrollment flag set to true from client side in preferences.
/// Default encryption private key and default self encryption keys are encrypted using APKAM symmetric key generated for the onboarding client.
@Deprecated('Use FirstEnrollmentRequest when onboarding an atSign')
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

  // ignore: deprecated_member_use_from_same_package
  /// Builds and returns an instance of [AtInitialEnrollmentRequest].
  @override
  // ignore: deprecated_member_use_from_same_package
  AtInitialEnrollmentRequest build() {
    // ignore: deprecated_member_use_from_same_package
    return AtInitialEnrollmentRequest.builder(this);
  }
}
