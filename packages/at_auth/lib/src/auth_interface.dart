import 'package:at_auth/at_auth.dart';

abstract class AtAuthInterface {
  AtEnrollmentBase atEnrollment(String atSign);

  AtAuth atAuth();
}
