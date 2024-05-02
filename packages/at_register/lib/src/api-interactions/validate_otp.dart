import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';

import '../../at_register.dart';

/// Task for validating the verification_code sent as part of the registration process.
///
/// Example usage:
/// ```dart
/// ValidateOtp validateOtpInstance = ValidateOtp();
/// RegisterTaskResult result = await validateOtpInstance.run(registerParams);
/// ```
/// CASE 1: 'If the email provided through registerParams does NOT have any existing atsigns':
/// cramKey will be present in result.data[[RegistrarConstants.cramKeyName]]
///
/// CASE 2: 'If the email provided through registerParams has existing atsigns':
/// list of existingAtsigns will be present in result.data[[RegistrarConstants.fetchedAtsignListName]]
/// and the new atsign in result.data[[RegistrarConstants.newAtsignName]];
/// Now, to fetch the cram key select one atsign (existing/new); populate this atsign
/// in registerParams and retry this task. Output will be as described in 'CASE 1'
class ValidateOtp extends RegisterTask {
  ValidateOtp(
      {RegistrarApiAccessor? apiAccessorInstance, bool allowRetry = false})
      : super(
            registrarApiAccessorInstance: apiAccessorInstance,
            allowRetry: allowRetry);

  @override
  String get name => 'ValidateOtpTask';

  @override
  Future<RegisterTaskResult> run(RegisterParams params) async {
    validateInputParams(params);
    RegisterTaskResult result = RegisterTaskResult();
    try {
      logger.info('Validating code with ${params.atsign}...');
      params.atsign = AtUtils.fixAtSign(params.atsign!);
      final validateOtpApiResult = await registrarApiAccessor.validateOtp(
        params.atsign!,
        params.email!,
        params.otp!,
        confirmation: params.confirmation,
        authority: RegistrarConstants.authority,
      );

      switch (validateOtpApiResult.taskStatus) {
        case ValidateOtpStatus.retry:
          if (canThrowException()) {
            throw InvalidVerificationCodeException(
                'Verification Failed: Incorrect verification code provided');
          }
          logger.warning('Invalid or expired verification code. Retrying...');
          params.otp ??= ApiUtil
              .readCliVerificationCode(); // retry reading otp from user through stdin
          if (shouldRetry()) {
            result.apiCallStatus = ApiCallStatus.retry;
            result.exception = InvalidVerificationCodeException(
                'Verification Failed: Incorrect verification code provided. Please retry the process again');
          } else {
            result.apiCallStatus = ApiCallStatus.failure;
            result.exception = ExhaustedVerificationCodeRetriesException(
                'Exhausted verification code retry attempts. Please restart the process');
          }
          break;

        case ValidateOtpStatus.followUp:
          params.confirmation = true;
          result.data['otp'] = params.otp;
          result.fetchedAtsignList = validateOtpApiResult.data['atsign'];
          result.data[RegistrarConstants.newAtsignName] =
              validateOtpApiResult.data[RegistrarConstants.newAtsignName];
          result.apiCallStatus = ApiCallStatus.retry;
          logger.finer(
              'Provided email has existing atsigns, please select one atsign and retry this task');
          break;

        case ValidateOtpStatus.verified:
          result.data[RegistrarConstants.cramKeyName] = validateOtpApiResult
              .data[RegistrarConstants.cramKeyName]
              .split(":")[1];
          logger.info('Cram secret verified');
          logger.info('Successful registration for ${params.email}');
          result.apiCallStatus = ApiCallStatus.success;
          break;

        case ValidateOtpStatus.failure:

        case null:

        default:
          result.apiCallStatus = ApiCallStatus.failure;
          result.exception = validateOtpApiResult.exception;
          break;
      }
    } on MaximumAtsignQuotaException {
      rethrow;
    } on ExhaustedVerificationCodeRetriesException {
      rethrow;
    } on InvalidVerificationCodeException {
      rethrow;
    } on Exception catch (e) {
      if (canThrowException()) {
        throw AtRegisterException(e.toString());
      }
      ApiUtil.handleException(result, e, shouldRetry());
    }
    return result;
  }

  @override
  void validateInputParams(RegisterParams params) {
    if (params.atsign.isNullOrEmpty) {
      throw IllegalArgumentException(
          'Atsign cannot be null for register-atsign-task');
    }
    if (params.email.isNullOrEmpty) {
      throw IllegalArgumentException(
          'e-mail cannot be null for register-atsign-task');
    }
    if (params.otp.isNullOrEmpty) {
      throw InvalidVerificationCodeException(
          'Verification code cannot be null/empty');
    }
  }
}
