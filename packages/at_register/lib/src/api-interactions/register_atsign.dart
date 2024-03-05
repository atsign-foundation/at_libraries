import 'package:at_commons/at_commons.dart';

import '../../at_register.dart';

/// User selects an atsign from the list fetched in [GetFreeAtsign].
///
/// Registers the selected atsign to the email provided through [RegisterParams].
///
/// Sets [RegisterTaskResult.apiCallStatus] if the HTTP GET/POST request gets any response other than STATUS_OK.
class RegisterAtsign extends RegisterTask {
  RegisterAtsign(super.registerParams,
      {super.registrarApiAccessorInstance, super.allowRetry});

  @override
  String get name => 'RegisterAtsignTask';

  @override
  Future<RegisterTaskResult> run() async {
    logger.info('Sending verification code to: ${registerParams.email}');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      result.data[RegistrarConstants.otpSentName] = (await registrarApiAccessor
              .registerAtSign(registerParams.atsign!, registerParams.email!,
                  authority: RegistrarConstants.authority))
          .toString();
      logger.info('Verification code sent to: ${registerParams.email}');
    } on Exception catch (e) {
      if (canThrowException()) {
        throw AtRegisterException(e.toString());
      }
      populateApiCallStatus(result, e);
    }
    result.apiCallStatus = ApiCallStatus.success;
    return result;
  }

  @override
  void validateInputParams() {
    if(registerParams.atsign.isNullOrEmpty){
      throw IllegalArgumentException('Atsign cannot be null for register-atsign-task');
    }
    if(registerParams.email.isNullOrEmpty){
      throw IllegalArgumentException('e-mail cannot be null for register-atsign-task');
    }
  }
}
