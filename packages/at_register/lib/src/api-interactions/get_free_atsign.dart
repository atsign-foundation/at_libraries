import 'package:at_commons/at_commons.dart';

import '../../at_register.dart';

/// A [RegisterTask] that fetches a list of free atsigns.
///
/// Throws an [AtException] with the concerned message encountered in the
/// HTTP GET/POST request.
///
/// Example usage:
/// ```dart
/// GetFreeAtsign getFreeAtsignInstance = GetFreeAtsign();
/// await getFreeAtsignInstance.init(RegisterParams(), RegistrarApiAccessor());
/// RegisterTaskResult result = await getFreeAtsignInstance.run();
/// ```
/// The fetched atsign will be stored in result.data['atsign'].
/// ToDo: write down what will be the structure inside result.data{}
class GetFreeAtsign extends RegisterTask {
  GetFreeAtsign(super.registerParams,
      {super.registrarApiAccessorInstance, super.allowRetry});

  @override
  String get name => 'GetFreeAtsignTask';

  @override
  Future<RegisterTaskResult> run() async {
    logger.info('Getting a randomly generated free atSign...');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      String atsign = await registrarApiAccessor.getFreeAtSigns(
          authority: RegistrarConstants.authority);
      logger.info('Fetched free atsign: $atsign');
      result.data['atsign'] = atsign;
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
    if(registerParams.email.isNullOrEmpty){
      throw IllegalArgumentException('email cannot be null for get-free-atsign-task');
    }
  }
}
