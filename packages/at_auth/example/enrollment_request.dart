import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_impl.dart';
import 'package:at_lookup/at_lookup.dart';

/// The example on submitting the [FirstEnrollmentRequest] which is used when onboarding an atSign and
/// [EnrollmentRequest] which is used by the subsequent mobile apps for authentication and authorization.
void main() async {
  AtLookUp atLookUp = AtLookupImpl('@alice', 'vip.ve.atsign.zone', 64);

  AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl('@alice');

  /// Onboarding an app for first time. Submit an enrollment and is auto approved.
  ///
  /// When an atsign is onboarded for the first time and enableEnrollment flag is set to true in AtClientPreferences,
  /// the enrollment is submitted to the server. Since, when onboarding for the first time, since there is no app
  /// to approve, the initial enrollment (Enrollment submitted on CRAM authenticated connection) is auto approved.
  /// If the enableEnrollment is set to false, then the enrollment is not submitted and the app will not be able
  /// to approve the other enrollment requests.
  ///
  /// The [appName] and [deviceName] are received from the AtOnboardingRequest.
  FirstEnrollmentRequest initialEnrollmentRequest = FirstEnrollmentRequest(
      appName: 'wavi',
      deviceName: 'my-device',
      apkamPublicKey: 'dummy_apkam_key',
      encryptedDefaultEncryptionPrivateKey: 'default-encryption-key',
      encryptedDefaultSelfEncryptionKey: 'default-self-encryption-key');

  // Contains the response from the server.
  // ignore: unused_local_variable
  AtEnrollmentResponse atEnrollmentResponse =
      await atEnrollmentBase.submit(initialEnrollmentRequest, atLookUp);

  // 2. The second app sending enrollment request to server:
  EnrollmentRequest enrollmentRequest = EnrollmentRequest(
      appName: 'wavi',
      deviceName: 'my-device',
      namespaces: {'wavi': 'rw'},
      apkamPublicKey: 'dummy_public_key',
      otp: '123',
      encryptedAPKAMSymmetricKey: 'enc_apkam_sym_key');

  // Internally, the apkam symmetric key is generated and set to enrollmentRequest
  enrollmentRequest.encryptedAPKAMSymmetricKey = 'dummy_encrypted_key';

  // Contains the response from the server.
  atEnrollmentResponse =
      await atEnrollmentBase.submit(enrollmentRequest, atLookUp);
}
