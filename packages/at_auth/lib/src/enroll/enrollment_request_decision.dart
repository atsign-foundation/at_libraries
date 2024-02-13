import 'dart:core';

import 'package:at_commons/at_commons.dart';

/// Represents the class to approve or deny an enrollment request.
///
/// ```dart
///  To approve an enrollment request
///
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
