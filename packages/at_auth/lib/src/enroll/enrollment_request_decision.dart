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
/// key are encrypted with the APKAM symmetric key and transmitted to the server.
///
/// If the request is denied, the requester is prevented from logging into the application.
///
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

  static EnrollmentRequestDecision denied(String enrollmentId) {
    return EnrollmentRequestDecision._()
      .._enrollmentId = enrollmentId
      .._enrollOperationEnum = EnrollOperationEnum.deny;
  }
}

class ApprovedRequestDecisionBuilder {
  String enrollmentId;
  String encryptedAPKAMSymmetricKey;

  ApprovedRequestDecisionBuilder(
      {required this.enrollmentId, required this.encryptedAPKAMSymmetricKey});
}
