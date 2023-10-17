import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

import 'syntax_test.dart';

void main() {
  group('A group of tests related to OTP verb syntax', () {
    test('A test to verify otp:get regex', () {
      Map<dynamic, dynamic> verbParams =
          getVerbParams(VerbSyntax.otp, "otp:get");
      expect(verbParams[AtConstants.operation], "get");
      expect(verbParams['ttl'], null);
      expect(verbParams['otp'], null);
    });

    test('A test to verify otp:get regex with TTL', () {
      Map<dynamic, dynamic> verbParams =
      getVerbParams(VerbSyntax.otp, "otp:get:ttl:100");
      expect(verbParams[AtConstants.operation], "get");
      expect(verbParams['ttl'], '100');
      expect(verbParams['otp'], null);
    });
  });
}
