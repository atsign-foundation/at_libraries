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
      // validates that exception was thrown
      expect(exceptionFlag, true);
    });
  });

  group('Group of tests to validate behaviour of RegisterAtsign', () {
    setUp(() => resetMocktailState());

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
      // validates that an exception was thrown
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
        assert(e.toString().contains('another new random exception'));
        exceptionFlag = true;
      }
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
      expect(params.confirmation, true); // confirmation set to true by the Task
      expect(result.apiCallStatus, ApiCallStatus.retry);

      // The above case is when an email has already existing atsigns, select an atsign
      // from the list and retry the task with confirmation set to 'true'
      // mimic-ing a user selecting an atsign and proceeding ahead
      params.atsign = atsign2;
      result = await validateOtpTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data[RegistrarConstants.cramKeyName], cram);
    });

    test('validate behaviour of ValidateOtp task - null or empty otp',
        () async {
      String atsign = '@charlie-otp-retry';
      String email = 'third-group-test-3@email';
      String? otp; // invalid null otp

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;
      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);

      expect(() async => await validateOtpTask.run(),
          throwsA(predicate((e) => e is InvalidVerificationCodeException)));

      params.otp = '';
      expect(() async => await validateOtpTask.run(),
          throwsA(predicate((e) => e is InvalidVerificationCodeException)));
    });

    test('validate behaviour of ValidateOtp task - incorrect otp', () async {
      String atsign = '@charlie-otp-incorrect';
      String email = 'third-group-test-3-3@email';
      String otp = 'otpp'; // invalid otp

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      ValidateOtpResult validateOtpResult = ValidateOtpResult()
        ..taskStatus = ValidateOtpStatus.retry
        ..apiCallStatus = ApiCallStatus.success
        ..exceptionMessage = 'incorrect otp';
      when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenAnswer((invocation) => Future.value(validateOtpResult));

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);

      expect(
          () async => await validateOtpTask.run(),
          throwsA(predicate((e) =>
              e is InvalidVerificationCodeException &&
              e.message.contains('incorrect otp'))));
    });

    test(
        'validate behaviour of ValidateOtp task - maximum free atsign limit reached',
        () async {
      String atsign = '@charlie-otp-incorrect';
      String email = 'third-group-test-3-3@email';
      String otp = 'otpp';

      var params = RegisterParams()
        ..atsign = atsign
        ..confirmation = false
        ..email = email
        ..otp = otp;

      when(() => mockRegistrarApiAccessor.validateOtp(atsign, email, otp,
              confirmation: false))
          .thenThrow(
              MaximumAtsignQuotaException('maximum free atsign limit reached'));

      ValidateOtp validateOtpTask = ValidateOtp(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor);

      expect(() async => await validateOtpTask.run(),
          throwsA(predicate((e) => e is MaximumAtsignQuotaException)));
    });
  });
}
