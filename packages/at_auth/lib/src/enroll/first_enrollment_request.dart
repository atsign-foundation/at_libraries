import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/base_enrollment_request.dart';

/// The FirstEnrollmentRequest represents an enrollment request when onboarding (activating) an atSign.
///
/// Upon submitting the [FirstEnrollmentRequest], an APKAM key pair and an encryption key pair are generated, and an enrollment
/// request is sent to the server. The server assigns the "__manage" namespace, which has access to all namespaces and serves as
/// the administrator app responsible for approving subsequent enrollment requests.
///
/// ```dart
/// Example on submitting FirstEnrollmentRequest
///   FirstEnrollmentRequest firstEnrollmentRequest = FirstEnrollmentRequest(
///               appName: 'wavi',
///               deviceName: 'iphone',
///               apkamPublicKey: 'dummy-apkam-public key', // Generated by the system
///               encryptedDefaultEncryptionPrivateKey: 'dummy-encrypted-private-key', // Generated by the system and encrypted by the APKAM symmetric key
///               encryptedDefaultSelfEncryptionKey: 'dummy-self-encryption-key'); // Generated by the system and encrypted by the APKAM symmetric key);
///```
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
