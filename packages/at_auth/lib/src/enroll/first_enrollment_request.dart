import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/base_enrollment_request.dart';

/// The FirstEnrollmentRequest represents an enrollment request when onboarding (activating) an atSign.
///
/// When onboarding an atSign, an enrollment with access to  __manage namespace is submitted which is auto approved.The App name,
/// deviceName are supplied from the mobile app via the [AtOnboardingRequest].
///
/// Two pair of RSA key pairs one for authentication which is called APKAM keys and other for shared data encryption
/// which is called encryption key pair. Two AES keys pairs self data encryption and APKAM encryption key.
///
/// The APKAM public key is stored in the secondary server. The default encryption private key and self encryption keys are
/// encrypted with the APKAM symmetric key and stored into the server.

class FirstEnrollmentRequest extends BaseEnrollmentRequest {
  String encryptedDefaultEncryptionPrivateKey;
  String encryptedDefaultSelfEncryptionKey;

  FirstEnrollmentRequest(
      {required super.appName,
      required super.deviceName,
      required super.apkamPublicKey,
      required this.encryptedDefaultEncryptionPrivateKey,
      required this.encryptedDefaultSelfEncryptionKey});
}
