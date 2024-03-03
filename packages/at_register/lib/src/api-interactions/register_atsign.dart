import '../../at_register.dart';

/// User selects an atsign from the list fetched in [GetFreeAtsign].
///
/// Registers the selected atsign to the email provided through [RegisterParams].
///
/// Sets [RegisterTaskResult.apiCallStatus] if the HTTP GET/POST request gets any response other than STATUS_OK.
class RegisterAtsign extends RegisterTask {
  RegisterAtsign(super.registerParams, {super.registrarApiAccessorInstance});

  @override
  String get name => 'RegisterAtsignTask';

  @override
  Future<RegisterTaskResult> run({bool allowRetry = false}) async {
    logger.info('Sending verification code to: ${registerParams.email}');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      result.data['otpSent'] = (await registrarApiAccessor.registerAtSign(
              registerParams.atsign!, registerParams.email!,
              authority: RegistrarConstants.authority))
          .toString();
      logger.info('Verification code sent to: ${registerParams.email}');
    } on Exception catch (e) {
      if (!allowRetry) {
        throw AtRegisterException(e.toString());
      }
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
      result.exceptionMessage = e.toString();
    }
    result.apiCallStatus = ApiCallStatus.success;
    return result;
  }
}
