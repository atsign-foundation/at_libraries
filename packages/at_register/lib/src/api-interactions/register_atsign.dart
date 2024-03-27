import 'package:at_commons/at_commons.dart';

import 'package:at_register/at_register.dart';

/// User selects an atsign from the list fetched in [GetFreeAtsign].
///
/// Registers the selected atsign to the email provided through [RegisterParams].
///
/// Sets [RegisterTaskResult.apiCallStatus] if the HTTP GET/POST request gets
/// any response other than STATUS_OK.
///
/// Example usage:
/// ```dart
/// RegisterAtsign registerAtsignInstance = RegisterAtsign();
/// RegisterTaskResult result = await registerAtsignInstance.run(registerParams);
/// ```
/// If verification code has been successfully delivered to email,
/// result.data[[RegistrarConstants.otpSentName]] will be set to true, otherwise false
class RegisterAtsign extends RegisterTask {
  RegisterAtsign(
      {RegistrarApiAccessor? apiAccessorInstance, bool allowRetry = false})
      : super(
            registrarApiAccessorInstance: apiAccessorInstance,
            allowRetry: allowRetry);

  @override
  String get name => 'RegisterAtsignTask';

  @override
  Future<RegisterTaskResult> run(RegisterParams params) async {
    validateInputParams(params);
    logger.info('Sending verification code to: ${params.email}');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      bool otpSent = await registrarApiAccessor.registerAtSign(
          params.atsign!, params.email!,
          authority: RegistrarConstants.authority);
      result.data[RegistrarConstants.otpSentName] = otpSent;
      if (otpSent) {
        logger.info('Verification code sent to: ${params.email}');
        result.apiCallStatus = ApiCallStatus.success;
      } else {
        logger.severe('Could NOT Verification code sent to: ${params.email}.'
            ' Please try again');
        result.apiCallStatus = ApiCallStatus.retry;
      }
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
  }
}
