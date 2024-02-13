import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/base_enrollment_request.dart';
import 'package:at_lookup/at_lookup.dart';

import 'enrollment_request_decision.dart';

/// An abstract class for submitting and managing the enrollment requests.
abstract class AtEnrollmentBase {
  /// Submits an enrollment request.
  ///
  /// The [atEnrollmentRequest] parameter represents the enrollment request details.
  /// The [atLookUp] parameter is used to perform lookups to secondary server
  /// to submit an enrollment request.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the enrollment.
  Future<AtEnrollmentResponse> submit(
      BaseEnrollmentRequest baseEnrollmentRequest, AtLookUp atLookUp);

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
  @Deprecated("Use approve and deny methods")
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp);

  /// Approves an enrollment request.
  ///
  /// The [AtEnrollmentNotificationRequest] parameter represents the enrollment request details
  /// for approving the enrollment request.
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the approval/denial of an enrollment.
  Future<AtEnrollmentResponse> approve(
      EnrollmentRequestDecision enrollmentRequestDecision, AtLookUp atLookUp);

  /// Denies an enrollment request.
  ///
  /// The [atEnrollmentRequest] parameter represents the enrollment request details to
  /// deny an enrollment.
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the approval/denial of an enrollment.
  Future<AtEnrollmentResponse> deny(
      EnrollmentRequestDecision enrollmentRequestDecision, AtLookUp atLookUp);
}
