import 'package:at_auth/at_auth.dart';
import 'package:at_lookup/at_lookup.dart';

/// An abstract class for submitting and managing the enrollment requests.
abstract class AtEnrollmentBase {
  /// Submits an enrollment request.
  ///
  /// The [BaseEnrollmentRequest] is an abstract class and serves as the entity responsible for submitting the enrollment request. This
  /// class contains fields that are shared between the [FirstEnrollmentRequest] and [EnrollmentRequest] which are subclasses of
  /// [BaseEnrollmentRequest].
  ///
  /// Use the [FirstEnrollmentRequest] when onboarding (activating) an @ sign for the initial time. Upon submitting the
  /// [FirstEnrollmentRequest], an APKAM key pair and an encryption key pair are generated, and an enrollment request is sent to the
  /// server. The server assigns the "__manage" namespace, which has access to all namespaces and serves as the administrator app
  /// responsible for approving subsequent enrollment requests.
  ///
  /// ```dart
  /// Example on submitting FirstEnrollmentRequest
  ///   FirstEnrollmentRequest firstEnrollmentRequest = FirstEnrollmentRequest(
  ///               appName: 'wavi',
  ///               deviceName: 'iphone',
  ///               apkamPublicKey: 'dummy-apkam-public key', // Generated by the system
  ///               encryptedDefaultEncryptionPrivateKey: 'dummy-encrypted-private-key', // Generated by the system and encrypted by the APKAM symmetric key
  ///               encryptedDefaultSelfEncryptionKey: 'dummy-self-encryption-key'); // Generated by the system and encrypted by the APKAM symmetric key);
  ///
  ///     AtEnrollmentResponse? atEnrollmentResponse =
  ///         await atEnrollmentBase?.submit(initialEnrollmentRequest, atLookUp!);
  ///```
  /// Use [EnrollmentRequest] to submit subsequent enrollment requests to generate APKAM key-pair with limited access to the
  /// specified namespaces. The [EnrollmentRequest] accepts the appName, deviceName, namespaces and otp
  ///
  /// ```dart
  /// Example on submitting EnrollmentRequest
  ///   EnrollmentRequest enrollmentRequest = EnrollmentRequest(
  ///                     appName: 'wavi',
  ///                     deviceName: 'my-device',
  ///                     namespaces: {'wavi': 'rw'},
  ///                     otp: '123'
  ///                     // The APKAM public key is generated by the system
  ///                     apkamPublicKey: 'dummy_public_key',
  ///                     // The encryptedAPKAMSymmetricKey is generated by the system
  ///                     encryptedAPKAMSymmetricKey: 'enc_apkam_sym_key');
  ///
  ///     AtEnrollmentResponse? atEnrollmentResponse =
  ///         await atEnrollmentBase?.submit(initialEnrollmentRequest, atLookUp!);
  ///```
  ///
  /// The [atLookUp] parameter is used to perform lookups to secondary server to submit an enrollment request.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the enrollment.
  ///
  Future<AtEnrollmentResponse> submit(
      BaseEnrollmentRequest baseEnrollmentRequest, AtLookUp atLookUp);

  /// Approves an enrollment request.
  ///
  /// Accepts [EnrollmentRequestDecision] which encapsulates the necessary enrollment request details for approving the
  /// enrollment request.
  ///
  /// To approve the request, the "enrollmentId" and its corresponding "encryptedAPKAMSymmetricKey,"
  /// received through the notification, must be provided using the "AuthenticationRequestDecisionBuilder."
  ///
  /// Upon approval, the encryptedAPKAMSymmetricKey undergoes decryption using the default encryption public key to
  /// retrieve the original APKAM Symmetric key. Subsequently, the default encryption key pair and the self-encryption
  /// key are encrypted with the APKAM symmetric key and transmitted to the server.
  ///
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the result of the approval/denial of an enrollment.
  ///
  /// ```dart
  ///  To approve an enrollment request
  ///
  /// AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl('@alice');
  /// AtLookup atLookup = AtLookupImpl('@alice', 'dummy-root-domain', 64);
  ///
  /// EnrollmentRequestDecision enrollmentRequestDecision =
  ///           EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
  ///               enrollmentId: 'dummy-enrollment-id',
  ///               encryptedAPKAMSymmetricKey: 'dummy-encrypted-apkam-symmetric-key'));
  ///
  /// AtEnrollmentResponse atEnrollmentResponse = await atEnrollmentBase.approve(
  ///       enrollmentRequestDecision, atLookupImpl);
  /// ```
  Future<AtEnrollmentResponse> approve(
      EnrollmentRequestDecision enrollmentRequestDecision, AtLookUp atLookUp);

  /// Denies an enrollment request.
  ///
  /// Accepts [EnrollmentRequestDecision] which encapsulates the enrollment request details necessary to deny an enrollment.
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the result of the approval/denial of an enrollment.
  ///
  /// ```dart
  ///  To approve an enrollment request
  ///
  /// AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl('@alice');
  /// AtLookup atLookup = AtLookupImpl('@alice', 'dummy-root-domain', 64);
  ///
  /// EnrollmentRequestDecision enrollmentRequestDecision = EnrollmentRequestDecision.denied('dummy-enrollment-id');
  /// AtEnrollmentResponse atEnrollmentResponse = await atEnrollmentBase.deny(enrollmentRequestDecision, atLookupImpl);
  /// ```
  Future<AtEnrollmentResponse> deny(
      EnrollmentRequestDecision enrollmentRequestDecision, AtLookUp atLookUp);

  /// Submits an enrollment request.
  ///
  /// The [atEnrollmentRequest] parameter represents the enrollment request details.
  /// The [atLookUp] parameter is used to perform lookups to secondary server
  /// to submit an enrollment request.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the enrollment.
  @Deprecated("Use submit method")
  Future<AtEnrollmentResponse> submitEnrollment(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp);

  /// Manages the approval/denial of an enrollment request.
  ///
  /// The [atEnrollmentRequest] parameter represents the enrollment request details.
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the approval/denial of an enrollment.
  @Deprecated("Use approve and deny methods to approve or deny an enrollment respectively")
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp);
}
