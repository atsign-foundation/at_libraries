import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';

import '../../at_register.dart';

/// Task for validating the verification_code sent as part of the registration process.
class ValidateOtp extends RegisterTask {
  ValidateOtp(super.registerParams,
      {super.registrarApiAccessorInstance, bool confirmation = false});

  @override
  String get name => 'ValidateOtpTask';

  @override
  Future<RegisterTaskResult> run({bool allowRetry = false}) async {
    RegisterTaskResult result = RegisterTaskResult();
    if (registerParams.otp.isNullOrEmpty) {
      throw InvalidVerificationCodeException(
          'Verification code cannot be null');
    }
    try {
      logger
          .info('Validating verification code for ${registerParams.atsign}...');
      registerParams.atsign = AtUtils.fixAtSign(registerParams.atsign!);
      final validateOtpApiResult = await registrarApiAccessor.validateOtp(
        registerParams.atsign!,
        registerParams.email!,
        registerParams.otp!,
        confirmation: registerParams.confirmation,
        authority: RegistrarConstants.authority,
      );

      switch (validateOtpApiResult.taskStatus) {
        case ValidateOtpStatus.retry:
          if (!allowRetry) {
            throw InvalidVerificationCodeException(
                'Verification Failed: Incorrect verification code provided');
          } else {
            logger.warning('Invalid or expired verification code. Retrying...');
            registerParams.otp ??= ApiUtil
                .readCliVerificationCode(); // retry reading otp from user through stdin
            result.apiCallStatus =
                shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
            result.exceptionMessage =
                'Verification Failed: Incorrect verification code provided. Please retry the process again';
          }
          break;

        case ValidateOtpStatus.followUp:
          registerParams.confirmation = true;
          result.data['otp'] = registerParams.otp;
          result.apiCallStatus = ApiCallStatus.retry;
          logger.finer(
              'Provided email has existing atsigns, please select one atsign and retry this task');
          break;

        case ValidateOtpStatus.verified:
          result.data[RegistrarConstants.cramKeyName] = validateOtpApiResult
              .data[RegistrarConstants.cramKeyName]
              .split(":")[1];
          logger.info('Cram secret verified.');
          logger.shout('Successful registration for ${registerParams.email}');
          result.apiCallStatus = ApiCallStatus.success;
          break;

        case ValidateOtpStatus.failure:
          result.apiCallStatus = ApiCallStatus.failure;
          result.exceptionMessage = validateOtpApiResult.exceptionMessage;
          break;
        case null:
          result.apiCallStatus = ApiCallStatus.failure;
          result.exceptionMessage = validateOtpApiResult.exceptionMessage;
          break;
      }
    } on MaximumAtsignQuotaException {
      rethrow;
    } on ExhaustedVerificationCodeRetriesException {
      rethrow;
    } on InvalidVerificationCodeException {
      rethrow;
    } catch (e) {
      if (!allowRetry) {
        throw AtRegisterException(e.toString());
      }
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
      result.exceptionMessage = e.toString();
    }
    return result;
  }
}
