import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_impl.dart';
import 'package:at_auth/src/enroll/enrollment_request_decision.dart';
import 'package:at_lookup/at_lookup.dart';

void main() async {
  AtLookupImpl atLookupImpl = AtLookupImpl('@alice', 'vip.ve.atsign.zone', 64);
  // Approve enrollment
  EnrollmentRequestDecision approveEnrollmentRequestDecision =
      EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
          enrollmentId: '123',
          encryptedAPKAMSymmetricKey: 'enc_apkam_sym_key'));

  AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl('@alice');
  AtEnrollmentResponse atEnrollmentResponse = await atEnrollmentBase.approve(
      approveEnrollmentRequestDecision, atLookupImpl);

  print(atEnrollmentResponse);

  // Deny Enrollment
  EnrollmentRequestDecision denyEnrollmentRequestDecision =
      EnrollmentRequestDecision.denied('abc-1234');
  atEnrollmentResponse =
      await atEnrollmentBase.deny(denyEnrollmentRequestDecision, atLookupImpl);

  print(atEnrollmentResponse);
}
