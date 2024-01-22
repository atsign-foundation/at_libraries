import 'package:at_auth/at_auth.dart';
import 'package:at_lookup/at_lookup.dart';

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
  Future<AtEnrollmentResponse> submitEnrollment(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp);

  /// Manages the approval/denial of an enrollment request.
  ///
  /// The [atEnrollmentRequest] parameter represents the enrollment request details.
  /// The [atLookUp] parameter is used to perform lookups during approval management.
  ///
  /// Returns a [Future] containing an [AtEnrollmentResponse] representing the
  /// result of the approval/denial of an enrollment.
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp);
}
