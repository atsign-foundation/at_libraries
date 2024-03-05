import 'package:at_onboarding_cli/src/register_cli/registration_flow.dart';
import 'package:at_register/at_register.dart';
import 'package:at_utils/at_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRegistrarApiCall extends Mock implements RegistrarApiAccessor {}

void main() {
  RegistrarApiAccessor accessorInstance = MockRegistrarApiCall();
  AtSignLogger.root_level = 'finer';

  group('A group of tests to validate GetFreeAtsign', () {
    setUp(() => resetMocktailState());

    test('validate behaviour of GetFreeAtsign - encounters exception',
        () async {
      when(() => accessorInstance.getFreeAtSigns())
          .thenThrow(Exception('random exception'));

      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      GetFreeAtsign getFreeAtsign = GetFreeAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);
      try {
        await RegistrationFlow().add(getFreeAtsign).start();
      } on Exception catch (e) {
        expect(e.runtimeType, AtRegisterException);
        expect(e.toString().contains('random exception'), true);
      }
      expect(getFreeAtsign.retryCount, getFreeAtsign.maximumRetries);
      expect(getFreeAtsign.shouldRetry(), false);
    });
  });

  group('Group of tests to validate behaviour of RegisterAtsign', () {
    setUp(() => resetMocktailState());

    test('RegisterAtsign params reading and updating - negative case',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => accessorInstance.registerAtSign(atsign, email))
          .thenAnswer((_) => Future.value(false));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      await RegistrationFlow().add(registerAtsignTask).start();
      expect(registerAtsignTask.retryCount, registerAtsignTask.maximumRetries);
      expect(registerAtsignTask.shouldRetry(), false);
    });

    test('verify behaviour of RegisterAtsign processing an exception',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => accessorInstance.registerAtSign(atsign, email))
          .thenThrow(Exception('another random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      expect(registerAtsignTask.retryCount, registerAtsignTask.maximumRetries);
      expect(registerAtsignTask.shouldRetry(), false);
      try {
        await RegistrationFlow().add(registerAtsignTask).start();
      } on Exception catch (e) {
        assert(e is AtRegisterException &&
            e.message.contains('another random exception'));
      }
    });

    test(
        'verify behaviour of RegistrationFlow processing exception in RegisterAtsign',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      when(() => accessorInstance.registerAtSign(atsign, email))
          .thenThrow(Exception('another new random exception'));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      try {
        await RegistrationFlow().add(registerAtsignTask).start();
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
        'validate positive behaviour of ValidateOtp task - need to followUp with confirmation set to true',
        () async {
      // In this test Registration flow is supposed to call the validateOtpTask
      // with confirmation first set to false and then with true without dev
      // intervention
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
      when(() => accessorInstance.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.verified
        ..apiCallStatus = ApiCallStatus.success
        ..data = {RegistrarConstants.cramKeyName: '$atsign:$cram'};
      when(() => accessorInstance.validateOtp(atsign, email, otp,
              confirmation: true))
          .thenAnswer((invocation) => Future.value(validateOtpResult2));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);
      RegisterTaskResult result =
          await RegistrationFlow().add(validateOtpTask).start();

      expect(result.data[RegistrarConstants.cramKeyName], cram);
      expect(params.confirmation, true);
      expect(validateOtpResult2.taskStatus, ValidateOtpStatus.verified);

      expect(validateOtpTask.retryCount, 2);
      expect(validateOtpTask.shouldRetry(), true);
    });

    test('validate behaviour of ValidateOtp task - 3 otp retries exhausted',
        () async {
      String atsign = '@charlie-retry';
      String email = 'third-group-test-3@email';
      String otp = 'bcaa';
      String cram = 'craaaaaaaaaaaam';
      ValidateOtpResult validateOtpResult = ValidateOtpResult();
      validateOtpResult.taskStatus = ValidateOtpStatus.retry;
      validateOtpResult.apiCallStatus = ApiCallStatus.success;
      validateOtpResult.data = {
        RegistrarConstants.cramKeyName: '$atsign:$cram'
      };
      when(() => accessorInstance.validateOtp(atsign, email, otp,
              confirmation: any(named: "confirmation")))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);
      expect(() async => await RegistrationFlow().add(validateOtpTask).start(),
          throwsA(ExhaustedVerificationCodeRetriesException));

      expect(validateOtpTask.retryCount, validateOtpTask.maximumRetries);
      expect(validateOtpTask.shouldRetry(), false);
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
      when(() => accessorInstance.getFreeAtSigns())
          .thenAnswer((invocation) => Future.value(atsign));
      // mock for register-atsign
      when(() => accessorInstance.registerAtSign(atsign, email))
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
      when(() => accessorInstance.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtpResult validateOtpResult2 = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.verified
        ..apiCallStatus = ApiCallStatus.success
        ..data = {RegistrarConstants.cramKeyName: '$atsign:$cram'};
      when(() => accessorInstance.validateOtp(atsign, email, otp,
              confirmation: true))
          .thenAnswer((invocation) => Future.value(validateOtpResult2));

      RegisterParams params = RegisterParams()
        ..email = email
        ..otp = otp
        ..confirmation = false;

      GetFreeAtsign getFreeAtsignTask = GetFreeAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: accessorInstance, allowRetry: true);

      await RegistrationFlow()
          .add(getFreeAtsignTask)
          .add(registerAtsignTask)
          .add(validateOtpTask)
          .start();

      expect(params.atsign, atsign);
      expect(params.cram, cram);
      expect(params.confirmation, true);
    });
  });
}
