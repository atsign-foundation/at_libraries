import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_impl.dart';
import 'package:at_lookup/at_lookup.dart';

void main() async {
  AtLookUp atLookUp = AtLookupImpl('@alice', 'vip.ve.atsign.zone', 64);

  AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl('@alice');

  // 1. Onboarding an app for first time. Submit an enrollment and is auto approved.
  // We get the above details from the AtOnboardingRequest.
  FirstEnrollmentRequest initialEnrollmentRequest = FirstEnrollmentRequest(
      appName: 'wavi',
      deviceName: 'my-device',
      apkamPublicKey: 'dummy_apkam_key',
      encryptedDefaultEncryptionPrivateKey: 'default-encryption-key',
      encryptedDefaultSelfEncryptionKey: 'default-self-encryption-key');

  // Contains the response from the server.
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

  // Intenally, the apkam symmetric key is generated and set to enrollmentRequest
  enrollmentRequest.encryptedAPKAMSymmetricKey = 'dummy_encrypted_key';

  // Contains the response from the server.
  atEnrollmentResponse =
      await atEnrollmentBase.submit(enrollmentRequest, atLookUp);
}
