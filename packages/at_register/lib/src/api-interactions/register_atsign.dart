import '../../at_register.dart';

/// User needs to select an atsign from the list fetched in [GetFreeAtsign].
///
/// Registers the selected atsign to the email provided through [RegisterParams]
///
/// sets [RegisterTaskResult.apiCallStatus] if the HTTP GET/POST request gets any response other than STATUS_OK
///
/// Note: Provide an atsign through [RegisterParams] if it is not ideal to read
/// user choice through [stdin]
class RegisterAtsign extends RegisterTask {
  @override
  String get name => 'RegisterAtsignTask';

  @override
  Future<RegisterTaskResult> run() async {
    logger.info('Sending verification code to: ${registerParams.email}');
    try {
      result.data['otpSent'] = (await registrarApiCalls.registerAtSign(
              registerParams.atsign!, registerParams.email!,
              authority: RegistrarConstants.authority))
          .toString();
      logger.info('Verification code sent to: ${registerParams.email}');
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}
