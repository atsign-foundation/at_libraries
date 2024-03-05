import 'package:at_register/at_register.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockRegistrarApiAccessor extends Mock implements RegistrarApiAccessor {}

/// This test file validates the behaviour of implementations of [RegisterTask]
/// with optional param of [RegisterTask.run] 'allowRetry' set to true.
///
/// Expected behaviour with this param set to true is that the task handles the
/// exceptions and returns a valid [RegisterTaskResult] object
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
      final result = await getFreeAtsign.run();
      expect(result.data[RegistrarConstants.atsignName], '@alice');
    });

    test('validate behaviour of GetFreeAtsign - encounters exception',
        () async {
      String testExceptionMessage = 'random exception';
      when(() => mockRegistrarApiAccessor.getFreeAtSigns())
          .thenThrow(Exception(testExceptionMessage));

      RegisterParams params = RegisterParams()..email = 'abcd@gmail.com';
      GetFreeAtsign getFreeAtsign = GetFreeAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
      RegisterTaskResult? result = await getFreeAtsign.run();

      expect(result.apiCallStatus, ApiCallStatus.retry);
      assert(result.exceptionMessage!.contains(testExceptionMessage));
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
      RegisterTaskResult result = await registerAtsignTask.run();

      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data['otpSent'], 'false');
    });

    test('verify behaviour of RegisterAtsign processing an exception',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      String testException = 'another random exception';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenThrow(Exception(testException));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;

      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
      RegisterTaskResult? result = await registerAtsignTask.run();

      expect(registerAtsignTask.shouldRetry(), true);
      assert(result.exceptionMessage!.contains(testException));
    });

    test(
        'verify behaviour of RegistrationFlow processing exception in RegisterAtsign',
        () async {
      String atsign = '@bobby';
      String email = 'second-group@email';
      String testExceptionMessage = 'another new random exception';
      when(() => mockRegistrarApiAccessor.registerAtSign(atsign, email))
          .thenThrow(Exception(testExceptionMessage));

      RegisterParams params = RegisterParams()
        ..atsign = atsign
        ..email = email;
      RegisterAtsign registerAtsignTask = RegisterAtsign(params,
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);

      var result = await registerAtsignTask.run();
      assert(result.exceptionMessage!.contains(testExceptionMessage));
      expect(registerAtsignTask.retryCount, 1);
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);
      RegisterTaskResult result = await validateOtpTask.run();
      expect(params.confirmation,
          true); // confirmation set to true by RegisterTask
      expect(result.apiCallStatus, ApiCallStatus.retry);
      print(result.data);

      // The above case is when an email has already existing atsigns, select an atsign
      // from the list and retry the task with confirmation set to 'true'
      params.atsign = atsign2;
      result = await validateOtpTask.run();
      expect(result.apiCallStatus, ApiCallStatus.success);
      expect(result.data[RegistrarConstants.cramKeyName], cram);
    });

    test('validate behaviour of ValidateOtp task - invalid OTP', () async {
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);

      RegisterTaskResult result = await validateOtpTask.run();
      expect(result.apiCallStatus, ApiCallStatus.retry);
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
          registrarApiAccessorInstance: mockRegistrarApiAccessor,
          allowRetry: true);

      expect(() async => await validateOtpTask.run(),
          throwsA(predicate((e) => e is MaximumAtsignQuotaException)));
    });
  });
}
