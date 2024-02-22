import 'dart:collection';

import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_utils.dart';

import '../../at_register.dart';

///This is a [RegisterTask] that validates the otp which was sent as a part
///of [RegisterAtsign] to email provided in args
///throws [AtException] with concerned message which was encountered in the
///HTTP GET/POST request
class ValidateOtp extends RegisterTask {
  @override
  String get name => 'ValidateOtpTask';

  @override
  void init(
      RegisterParams registerParams, RegistrarApiCalls registrarApiCalls) {
    this.registerParams = registerParams;
    this.registrarApiCalls = registrarApiCalls;
    this.registerParams.confirmation = false;
    result.data = HashMap<String, String>();
    logger = AtSignLogger(name);
  }

  @override
  Future<RegisterTaskResult> run() async {
    registerParams.otp ??= ApiUtil.getVerificationCodeFromUser();
    logger.info('Validating your verification code...');
    try {
      registerParams.atsign = AtUtils.fixAtSign(registerParams.atsign!);
      ValidateOtpResult validateOtpApiResult =
          await registrarApiCalls.validateOtp(registerParams.atsign!,
              registerParams.email!, registerParams.otp!,
              confirmation: registerParams.confirmation,
              authority: RegistrarConstants.authority);
      if (validateOtpApiResult.taskStatus == ValidateOtpStatus.retry) {
        logger.severe('Invalid or expired verification code.'
                ' Check your verification code and try again.');

        /// ToDo: how can an overrided ApiUtil be injected here
        registerParams.otp = ApiUtil.getVerificationCodeFromUser();
        result.apiCallStatus =
            shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
        result.exceptionMessage =
            'Incorrect otp entered 3 times. Max retries reached.';
      } else if (validateOtpApiResult.taskStatus ==
          ValidateOtpStatus.followUp) {
        registerParams.confirmation = true;
        result.data['otp'] = registerParams.otp;
        result.apiCallStatus = ApiCallStatus.retry;
      } else if (validateOtpApiResult.taskStatus ==
          ValidateOtpStatus.verified) {
        result.data[RegistrarConstants.cramKey] =
            validateOtpApiResult.data[RegistrarConstants.cramKey].split(":")[1];

        logger.info('Your cram secret: ${result.data['cramkey']}');
        logger.shout('Your atSign **@${registerParams.atsign}** has been'
            ' successfully registered to ${registerParams.email}');
        result.apiCallStatus = ApiCallStatus.success;
      } else if (validateOtpApiResult.taskStatus == ValidateOtpStatus.failure) {
        result.apiCallStatus = ApiCallStatus.failure;
        result.exceptionMessage = validateOtpApiResult.exceptionMessage;
      }
    } on MaximumAtsignQuotaException {
      rethrow;
    } on ExhaustedVerificationCodeRetriesException {
      rethrow;
    } on AtException catch (e) {
      result.exceptionMessage = e.message;
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}
