import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/at_auth_impl.dart';
import 'package:at_auth/src/auth/cram_authenticator.dart';
import 'package:at_auth/src/auth/pkam_authenticator.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_lookup/at_lookup.dart';

import 'enroll/at_enrollment_impl.dart';

abstract class AtAuthInterface {
  AtEnrollmentBase atEnrollment(String atSign);

  AtAuth atAuth();
}
