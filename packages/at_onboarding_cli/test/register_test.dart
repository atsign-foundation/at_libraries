import 'dart:collection';

import 'package:at_onboarding_cli/src/register_cli/register.dart';
import 'package:at_onboarding_cli/src/util/api_call_status.dart';
import 'package:at_onboarding_cli/src/util/register_api_constants.dart';
import 'package:at_onboarding_cli/src/util/register_api_result.dart';
import 'package:at_onboarding_cli/src/util/register_util.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRegisterUtil extends Mock implements RegisterUtil {}

class RegisterTest {
  static RegisterUtil registerUtil = MockRegisterUtil();

  static void defineMocking() {
    when(() => registerUtil.getFreeAtSigns())
        .thenAnswer((invocation) async => ['testatsign']);

    when(() => registerUtil.registerAtSign('testatsign', 'email@email.com'))
        .thenAnswer(((invocation) async => true));

    when(() => registerUtil.validateOtp(any(), any(), 'correctOtp',
        confirmation: 'false')).thenAnswer((invocation) async => 'follow-up');

    when(() => registerUtil.validateOtp(any(), any(), 'correctOtp',
            confirmation: 'true'))
        .thenAnswer((invocation) async => '@testatsign:craaaaaamkeeeeeey');

    when(() => registerUtil.validateOtp(
            'testatsign', 'email@email.com', 'wrongOtp'))
        .thenAnswer((invocation) async => 'retry');

    print(registerUtil.registerAtSign('testatsign', 'email@email.com'));
  }

  static Map<String, String> setParams(
      {String confirmation = 'true',
      String otp = 'correctOtp',
      addAtsign = false}) {
    Map<String, String> params = HashMap<String, String>();
    if (addAtsign) {
      params['atsign'] = 'testatsign';
    }
    params['confirmation'] = confirmation;
    params['email'] = 'email@email.com';
    params['authority'] = RegisterApiConstants.apiHostProd;
    params['otp'] = otp;

    return params;
  }
}

void main() {
  RegisterTest.defineMocking();

  group('test Registration flow', () async {
    Map<String, String> params = RegisterTest.setParams(confirmation: 'false');
    print(params);

    await RegistrationFlow(params, RegisterTest.registerUtil)
        .add(GetFreeAtsign())
        .add(RegisterAtsign())
        .add(ValidateOtp())
        .start();
    test('test atsign presence', () {
      expect('testatsign', params['atsign']);
    });
    test('test otpSent', () {
      expect('true', params['otpSent']);
    });
    test('test otp presence', () {
      expect('correctOtp', params['otp']);
    });

    test('test if confirmation changed to true', () {
      expect('true', params['confirmation']);
    });
    test('test cram key presence', () {
      expect('craaaaaamkeeeeeey', params['cramkey']);
    });

    reset(RegisterTest.registerUtil);
  });

  group('test validate otp class', () {
    ValidateOtp validateOtp = ValidateOtp();

    test('test with confirmation false and correct otp', () async {
      Map<String, String> localParams = RegisterTest.setParams(
          confirmation: 'false', otp: 'correctOtp', addAtsign: true);
      print(localParams);
      validateOtp.init(localParams, RegisterTest.registerUtil);
      RegisterApiResult result = await validateOtp.run();
      expect(result.data, {'otp': 'correctOtp'});
      expect(ApiCallStatus.retry, result.apiCallStatus);
      reset(RegisterTest.registerUtil);
    });

    test('test with confirmation true and correct otp', () async {
      Map<String, String> localParams =
          RegisterTest.setParams(otp: 'correctOtp', addAtsign: true);
      validateOtp.init(localParams, RegisterTest.registerUtil);
      RegisterApiResult result = await validateOtp.run();
      expect(result.data, {'cramkey': 'craaaaaamkeeeeeey'});
      expect(ApiCallStatus.success, result.apiCallStatus);
      reset(RegisterTest.registerUtil);
    });

    test('test with confirmation true and wrong otp', () async {
      Map<String, String> localParams = RegisterTest.setParams(
          confirmation: 'true', otp: 'wrongOtp', addAtsign: true);
      validateOtp.init(localParams, RegisterTest.registerUtil);
      RegisterApiResult result = await validateOtp.run();
      expect('retry', result.data);
      expect(ApiCallStatus.retry, result.apiCallStatus);
    });
  });
}
