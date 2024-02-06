import 'dart:io';

import '../../at_register.dart';

///This is a [RegisterTask] that registers a free atsign fetched in
///[GetFreeAtsign] to the email provided as args
///throws [AtException] with concerned message which was encountered in the
///HTTP GET/POST request
class RegisterAtsign extends RegisterTask {
  @override
  Future<RegisterTaskResult> run() async {
    stdout.writeln(
        '[Information] Sending verification code to: ${registerParams.email}');
    try {
      result.data['otpSent'] = (await registrarApiCalls.registerAtSign(
              registerParams.atsign!, registerParams.email!,
              authority: RegistrarConstants.authority))
          .toString();
      stdout.writeln(
          '[Information] Verification code sent to: ${registerParams.email}');
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}
