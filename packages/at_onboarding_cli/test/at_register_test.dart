import 'package:at_register/at_register.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRegistrarApiCall extends Mock implements RegistrarApiAccessor {}

void main() {
  RegistrarApiAccessor mockRegistrarApiCall = MockRegistrarApiCall();

  group('A group of tests to validate GetFreeAtsign', () {
    setUp(() => resetMocktailState());

    test('validate behaviour of GetFreeAtsign', () async {
      when(() => mockRegistrarApiCall.getFreeAtSigns())
          .thenAnswer((invocation) => Future.value('@alice'));

      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      await RegistrationFlow(params, mockRegistrarApiCall)
          .add(GetFreeAtsign())
          .start();
      expect(params.atsign, '@alice');
    });

    test('validate behaviour of GetFreeAtsign - encounters exception',
        () async {
      when(() => mockRegistrarApiCall.getFreeAtSigns())
          .thenThrow(Exception('random exception'));

      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      GetFreeAtsign getFreeAtsign = GetFreeAtsign();

      try {
        await RegistrationFlow(params, mockRegistrarApiCall)
            .add(getFreeAtsign)
            .start();
      } on Exception catch (e) {
        expect(e.runtimeType, AtRegisterException);
        expect(e.toString().contains('random exception'), true);
      }
      expect(getFreeAtsign.retryCount, RegisterTask.maximumRetries);
      expect(getFreeAtsign.result.apiCallStatus, ApiCallStatus.failure);
      expect(getFreeAtsign.shouldRetry(), false);
      expect(getFreeAtsign.retryCount, 3);
    });

    // test('fetch multiple atsigns using GetFreeAtsign', () async {
    //   String email = 'first-group-3@testland.test';
    //   when(() => mockRegistrarApiCall.getFreeAtSigns())
    //       .thenAnswer((invocation) => Future.value(['@alice', '@bob', '@charlie']));
    //
    //   RegisterParams params = RegisterParams()..email = email;
    //   GetFreeAtsign getFreeAtsignInstance = GetFreeAtsign(count: 3);
    //   getFreeAtsignInstance.init(params, mockRegistrarApiCall);
    //   RegisterTaskResult result = await getFreeAtsignInstance.run();
    //
    //   expect(result.data['atsign'], '');
    // });
  });

  group('Group of tests to validate behaviour of RegisterAtsign', () {
    setUp(() => resetMocktailState());

    test('validate RegisterAtsign behaviour in RegistrationFlow', () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(true));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign();
      await RegistrationFlow(params, mockRegistrarApiCall)
          .add(registerAtsignTask)
          .start();
      expect(registerAtsignTask.retryCount, 1); // 1 is the default retry count
      // this task does not generate any new params. This test validates how RegistrationFlow
      // processes the task when otp has been sent to user's email
      // successful execution of this test would indicate that the process did not
      // encounter any errors/exceptions
    });

    test('RegisterAtsign params reading and updating - positive case',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(true));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign();
      registerAtsignTask.init(params, mockRegistrarApiCall);
      RegisterTaskResult result = await registerAtsignTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data['otpSent'], 'true');
    });

    test('RegisterAtsign params reading and updating - negative case',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(false));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign();
      registerAtsignTask.init(params, mockRegistrarApiCall);
      RegisterTaskResult result = await registerAtsignTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data['otpSent'], 'false');
      expect(registerAtsignTask.shouldRetry(), true);
    });

    test('verify behaviour of RegisterAtsign processing an exception',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenThrow(Exception('another random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign();
      registerAtsignTask.init(params, mockRegistrarApiCall);
      RegisterTaskResult result = await registerAtsignTask.run();
      expect(result.apiCallStatus, ApiCallStatus.retry);
      expect(result.exceptionMessage, 'Exception: another random exception');
      expect(registerAtsignTask.shouldRetry(), true);
    });

    test(
        'verify behaviour of RegistrationFlow processing exception in RegisterAtsign',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenThrow(Exception('another new random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign();
      try {
        await RegistrationFlow(params, mockRegistrarApiCall)
            .add(registerAtsignTask)
            .start();
      } on Exception catch (e) {
        print(e.toString());
        assert(e.toString().contains('another new random exception'));
      }
      expect(registerAtsignTask.retryCount, 3);
      expect(registerAtsignTask.shouldRetry(), false);
    });
  });

  group('A group of tests to verify ValidateOtp task behaviour', () {
    setUp(() => resetMocktailState());

    test(
        'validate positive behaviour of ValidateOtp task - received cram in first call',
        () async {
      String atsign = '@charlie';
      String email = 'third-group@email';
      String otp = 'Abcd';
      String cram = 'craaaaaaaaaaaam';
      ValidateOtpResult validateOtpResult = ValidateOtpResult();
      validateOtpResult.taskStatus = ValidateOtpStatus.verified;
      validateOtpResult.apiCallStatus = ApiCallStatus.success;
      validateOtpResult.data = {RegistrarConstants.cramKey: '$atsign:$cram'};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      await RegistrationFlow(params, mockRegistrarApiCall)
          .add(ValidateOtp())
          .start();

      expect(params.cram, cram);
    });

    test(
        'validate positive behaviour of ValidateOtp task - need to followUp with confirmation set to true',
        () async {
      String atsign = '@charlie123';
      String email = 'third-group@email';
      String otp = 'bcde';
      String cram = 'craaaaaaaaaaaam1234';

      var mockApiRespData = {
        'atsign': ['@old-atsign'],
        'newAtsign': atsign
      };
      ValidateOtpResult validateOtpResult = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.followUp
        ..apiCallStatus = ApiCallStatus.success
        ..data = {'data': mockApiRespData};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.verified
        ..apiCallStatus = ApiCallStatus.success
        ..data = {RegistrarConstants.cramKey: '$atsign:$cram'};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: true))
          .thenAnswer((invocation) => Future.value(validateOtpResult2));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;
      // confirmation needs to be false for first call ?
      await RegistrationFlow(params, mockRegistrarApiCall)
          .add(ValidateOtp())
          .start();

      expect(params.cram, cram);
      expect(params.confirmation, true);
      expect(validateOtpResult2.taskStatus, ValidateOtpStatus.verified);
    });

    test('validate behaviour of ValidateOtp task - 3 otp retries exhausted',
        () async {
      String atsign = '@charlie-otp-retry';
      String email = 'third-group-test-3@email';
      String otp = 'bcaa';
      String cram = 'craaaaaaaaaaaam';
      ValidateOtpResult validateOtpResult = ValidateOtpResult();
      validateOtpResult.taskStatus = ValidateOtpStatus.retry;
      validateOtpResult.apiCallStatus = ApiCallStatus.success;
      validateOtpResult.data = {RegistrarConstants.cramKey: '$atsign:$cram'};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: any(named: "confirmation")))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;
      var validateOtpTask = ValidateOtp();
      expect(
          () async => await RegistrationFlow(params, mockRegistrarApiCall)
              .add(validateOtpTask)
              .start(),
          throwsA(ExhaustedVerificationCodeRetriesException));

      expect(validateOtpTask.retryCount, 3);
    });
  });

  group('test to validate all 3 API calls in sequence', () {
    setUp(() => resetMocktailState());

    test('verify all 3 API calls at once', () async {
      String atsign = '@lewis';
      String email = 'lewis44@gmail.com';
      String cram = 'craaaaaaaaaaaaam';
      String otp = 'Agbr';
      // mock for get-free-atsign
      when(() => mockRegistrarApiCall.getFreeAtSigns())
          .thenAnswer((invocation) => Future.value(atsign));
      // mock for register-atsign
      when(() => mockRegistrarApiCall.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(true));
      // rest of the mocks for validate-otp
      var mockApiRespData = {
        'atsign': ['@old-atsign'],
        'newAtsign': atsign
      };
      ValidateOtpResult validateOtpResult = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.followUp
        ..apiCallStatus = ApiCallStatus.success
        ..data = {'data': mockApiRespData};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.verified
        ..apiCallStatus = ApiCallStatus.success
        ..data = {RegistrarConstants.cramKey: '$atsign:$cram'};
      when(() => mockRegistrarApiCall.validateOtp(atsign, email, otp,
              confirmation: true))
          .thenAnswer((invocation) => Future.value(validateOtpResult2));

      RegisterParams params = RegisterParams()
        ..email = email
        ..otp = otp
        ..confirmation = false;

      await RegistrationFlow(params, mockRegistrarApiCall)
          .add(GetFreeAtsign())
          .add(RegisterAtsign())
          .add(ValidateOtp())
          .start();

      expect(params.atsign, atsign);
      expect(params.cram, cram);
      expect(params.confirmation, true);
    });
  });
}
