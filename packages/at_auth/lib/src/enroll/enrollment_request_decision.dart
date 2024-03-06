import 'dart:core';

import 'package:at_commons/at_commons.dart';

/// This class serves as the entity responsible for either approving or denying an enrollment request.
/// The enrollment request is received through a notification from the server. The approving app has
/// the authority to either grant or deny the request, with approval resulting in authentication and
/// authorization to the requested namespaces.
///
/// To approve the request, the "enrollmentId" and its corresponding "encryptedAPKAMSymmetricKey,"
/// received through the notification, must be provided using the "AuthenticationRequestDecisionBuilder."
///
/// Upon approval, the encryptedAPKAMSymmetricKey undergoes decryption using the default encryption public key to
/// retrieve the original APKAM Symmetric key. Subsequently, the default encryption key pair and the self-encryption
/// key are encrypted with the APKAM symmetric key and transmitted to the server for the requesting app. The requesting
/// app, then decrypts the encrypted default encryption private key and self encryption key. These keys are used for
/// decryption of shared data and self data respectively..
///
/// ```dart
///  To approve an enrollment request
///
/// EnrollmentRequestDecision enrollmentRequestDecision =
///           EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
///               enrollmentId: 'dummy-enrollment-id',
///               encryptedAPKAMSymmetricKey: 'dummy-encrypted-apkam-symmetric-key'));
/// ```
///
/// If the request is denied, the requester is prevented from logging into the application.
///
/// To deny an enrollment request
///
/// ```dart
///  EnrollmentRequestDecision enrollmentRequestDecision = EnrollmentRequestDecision.denied('dummy-enrollment-id');
/// ```
class EnrollmentRequestDecision {
  late final String _enrollmentId;
  late final String _encryptedAPKAMSymmetricKey;
  late final EnrollOperationEnum _enrollOperationEnum;

  String get enrollmentId => _enrollmentId;

  String get encryptedAPKAMSymmetricKey => _encryptedAPKAMSymmetricKey;

  EnrollOperationEnum get enrollOperationEnum => _enrollOperationEnum;

  // Private constructor to prevent creating object.
  // Use static factory methods to get instance of EnrollmentRequestDecision
  EnrollmentRequestDecision._();

  /// To approve the request, the "enrollmentId" and its corresponding "encryptedAPKAMSymmetricKey,"
  /// received through the notification, must be provided using the "AuthenticationRequestDecisionBuilder."
  ///
  /// Upon approval, the encryptedAPKAMSymmetricKey undergoes decryption using the default encryption public key to
  /// retrieve the original APKAM Symmetric key. Subsequently, the default encryption key pair and the self-encryption
  /// key are encrypted with the APKAM symmetric key and transmitted to the server for the requesting app. The requesting
  /// app, then decrypts the encrypted default encryption private key and self encryption key. These keys are used for
  /// decryption of shared data and self data respectively..
  ///
  /// ```dart
  ///  To approve an enrollment request
  ///
  /// EnrollmentRequestDecision enrollmentRequestDecision =
  ///           EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
  ///               enrollmentId: 'dummy-enrollment-id',
  ///               encryptedAPKAMSymmetricKey: 'dummy-encrypted-apkam-symmetric-key'));
  static EnrollmentRequestDecision approved(
      ApprovedRequestDecisionBuilder approvedRequestDecisionBuilder) {
    EnrollmentRequestDecision enrollmentRequestDecision =
        EnrollmentRequestDecision._()
          .._enrollmentId = approvedRequestDecisionBuilder.enrollmentId
          .._encryptedAPKAMSymmetricKey =
              approvedRequestDecisionBuilder.encryptedAPKAMSymmetricKey
          .._enrollOperationEnum = EnrollOperationEnum.approve;

    return enrollmentRequestDecision;
  }

  /// If the request is denied, the requester is prevented from logging into the application.
  ///
  /// ```dart
  ///  EnrollmentRequestDecision enrollmentRequestDecision = EnrollmentRequestDecision.denied('dummy-enrollment-id');
  /// ```
  static EnrollmentRequestDecision denied(String enrollmentId) {
    return EnrollmentRequestDecision._()
      .._enrollmentId = enrollmentId
      .._enrollOperationEnum = EnrollOperationEnum.deny;
  }
}

/// The class encapsulates the data required for approving an enrollment.
///
/// The enrollmentId is a unique identifier assigned to each enrollment request. This allows identification of individual requests to
/// perform the enrollment operations.
///
/// The encryptedAPKAMSymmetricKey is decrypted using default encryptionPublicKey. The original APKAMSymmetricKey is used to encrypt
/// the default encryption private key and the self encryption key and are sent to the server for the requesting app.
///
/// The requesting app, decrypts the encrypted default encryption private key and self encryption key. These keys are used for decryption
/// of shared data and self data respectively.
class ApprovedRequestDecisionBuilder {
  String enrollmentId;
  String encryptedAPKAMSymmetricKey;

  ApprovedRequestDecisionBuilder(
      {required this.enrollmentId, required this.encryptedAPKAMSymmetricKey});
}
