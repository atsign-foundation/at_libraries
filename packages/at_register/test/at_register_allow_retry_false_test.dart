import 'dart:collection';

import 'package:at_register/at_register.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRegistrarApiAccessor extends Mock implements RegistrarApiAccessor {}

void main() {
  MockRegistrarApiAccessor mockRegistrarApiAccessor =
      MockRegistrarApiAccessor();

  group('A group of tests to validate GetFreeAtsign', () {
    setUp(() => resetMocktailState());

    test('validate behaviour of GetFreeAtsign', () async {
      when(() => mockRegistrarApiAccessor.getFreeAtSigns())
          .thenAnswer((invocation) => Future.value('@alice'));
      print(mockRegistrarApiAccessor.getFreeAtSigns());
      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      GetFreeAtsign getFreeAtsign = GetFreeAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      final result = await getFreeAtsign.run();
      expect(result.data[RegistrarConstants.atsignName], '@alice');
    });

    test('validate behaviour of GetFreeAtsign - encounters exception',
        () async {
      when(() => mockRegistrarApiAccessor.getFreeAtSigns())
          .thenThrow(Exception('random exception'));

      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      GetFreeAtsign getFreeAtsign = GetFreeAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      bool exceptionFlag = false;
      try {
        await getFreeAtsign.run();
      } on Exception catch (e) {
        expect(e.runtimeType, AtRegisterException);
        expect(e.toString().contains('random exception'), true);
        exceptionFlag = true;
      }
      expect(getFreeAtsign.shouldRetry(), true);
      expect(exceptionFlag, true);
    });
  });

  group('Group of tests to validate behaviour of RegisterAtsign', () {
    setUp(() => resetMocktailState());

    test('validate RegisterAtsign behaviour in RegistrationFlow', () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(true));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      await registerAtsignTask.run();
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
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(true));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      RegisterTaskResult result = await registerAtsignTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data['otpSent'], 'true');
    });

    test('RegisterAtsign params reading and updating - negative case',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(false));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      RegisterTaskResult result = await registerAtsignTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data['otpSent'], 'false');
      expect(registerAtsignTask.shouldRetry(), true);
    });

    test('verify behaviour of RegisterAtsign processing an exception',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenThrow(Exception('another random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;

      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      bool exceptionFlag = false;
      try {
        await registerAtsignTask.run();
      } on Exception catch (e) {
        expect(e.runtimeType, AtRegisterException);
        expect(e.toString().contains('random exception'), true);
        exceptionFlag = true;
      }
      expect(registerAtsignTask.shouldRetry(), true);
      expect(exceptionFlag, true);
    });

    test(
        'verify behaviour of RegistrationFlow processing exception in RegisterAtsign',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenThrow(Exception('another new random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      bool exceptionFlag = false;
      try {
        await registerAtsignTask.run();
      } on Exception catch (e) {
        print(e.toString());
        assert(e.toString().contains('another new random exception'));
        exceptionFlag = true;
      }
      expect(registerAtsignTask.retryCount, 1);
      expect(exceptionFlag, true);
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
      validateOtpResult.data = {
        RegistrarConstants.cramKeyName: '$atsign:$cram'
      };
      when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      RegisterTaskResult result = await validateOtpTask.run();

      expect(result.data[RegistrarConstants.cramKeyName], cram);
    });

    test(
        'validate positive behaviour of ValidateOtp task - need to followUp with confirmation set to true',
        () async {
      String atsign = '@charlie123';
      String atsign2 = '@cheesecake';
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
      when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.verified
        ..apiCallStatus = ApiCallStatus.success
        ..data = {RegistrarConstants.cramKeyName: '$atsign:$cram'};
      when(() => mockRegistrarApiAccessor.validateOtp(atsign2, email, otp,
              confirmation: true))
          .thenAnswer((invocation) => Future.value(validateOtpResult2));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false // confirmation needs to be false for first call
        ..email = email
        ..otp = otp;

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);
      RegisterTaskResult result = await validateOtpTask.run();
      expect(params.confirmation, true);
      expect(result.apiCallStatus, ApiCallStatus.retry);
      expect(validateOtpResult2.taskStatus, ValidateOtpStatus.verified);

      // The above case is when an email has already existing atsigns, select an atsign
      // from the list and retry the task with confirmation set to 'true'
      params.atsign = atsign2;
      result = await validateOtpTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data[RegistrarConstants.cramKeyName], cram);
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
      validateOtpResult.data = {
        RegistrarConstants.cramKeyName: '$atsign:$cram'
      };
      when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
              confirmation: any(named: "confirmation")))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;
      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);

      expect(() async => await validateOtpTask.run(),
          throwsA(ExhaustedVerificationCodeRetriesException));

      expect(validateOtpTask.retryCount, 1);
    });
  });

  group('test to validate all 3 API calls in sequence', () {
    setUp(() => resetMocktailState());
    //
    // test('verify all 3 API calls in sequence', () async {
    //   String atsign = '@lewis';
    //   String email = 'lewis44@gmail.com';
    //   String cram = 'craaaaaaaaaaaaam';
    //   String otp = 'Agbr';
    //   // mock for get-free-atsign
    //   when(() => mockRegistrarApiAccessor.getFreeAtSigns())
    //       .thenAnswer((invocation) => Future.value(atsign));
    //   // mock for register-atsign
    //   when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
    //       .thenAnswer((_) => Future.value(true));
    //   // rest of the mocks for validate-otp
    //   var mockApiRespData = {
    //     'atsign': ['@old-atsign'],
    //     'newAtsign': atsign
    //   };
    //   ValidateOtpResult validateOtpResult = ValidateOtpResult()
    //     ..taskStatus = ValidateOtpStatus.followUp
    //     ..apiCallStatus = ApiCallStatus.success
    //     ..data = {'data': mockApiRespData};
    //   when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
    //           confirmation: false))
    //       .thenAnswer((invocation) => Future.value(validateOtpResult));
    //
    //   ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
    //     ..taskStatus = ValidateOtpStatus.verified
    //     ..apiCallStatus = ApiCallStatus.success
    //     ..data = {RegistrarConstants.cramKey: '$atsign:$cram'};
    //   when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
    //           confirmation: true))
    //       .thenAnswer((invocation) => Future.value(validateOtpResult2));
    //
    //   RegisterParams params = RegisterParams()
    //     ..email = email
    //     ..otp = otp
    //     ..confirmation = false;
    //
    //   await RegistrationFlow(params, mockRegistrarApiAccessor)
    //       .add(GetFreeAtsign())
    //       .add(RegisterAtsign())
    //       .add(ValidateOtp())
    //       .start();
    //
    //   expect(params.atsign, atsign);
    //   expect(params.cram, cram);
    //   expect(params.confirmation, true);
    // });
  });
}
