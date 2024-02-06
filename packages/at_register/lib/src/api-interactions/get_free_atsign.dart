import 'dart:io';

import '../../at_register.dart';

///This is a [RegisterTask] that fetches a free atsign
///throws [AtException] with concerned message which was encountered in the
///HTTP GET/POST request
class GetFreeAtsign extends RegisterTask {
  @override
  Future<RegisterTaskResult> run() async {
    stdout
        .writeln('[Information] Getting your randomly generated free atSign…');
    try {
      List<String> atsignList = await registrarApiCalls.getFreeAtSigns(
          count: 8, authority: RegistrarConstants.authority);
      result.data['atsign'] = atsignList[0];
      stdout.writeln('[Information] Your new atSign is **@${atsignList[0]}**');
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }

    return result;
  }
}
