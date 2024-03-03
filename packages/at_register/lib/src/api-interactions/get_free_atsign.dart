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
  GetFreeAtsign(super.registerParams, {super.registrarApiAccessorInstance});

  @override
  String get name => 'GetFreeAtsignTask';

  @override
  Future<RegisterTaskResult> run({bool allowRetry = false}) async {
    logger.info('Getting a randomly generated free atSign...');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      String atsign = await registrarApiAccessor.getFreeAtSigns(
          authority: RegistrarConstants.authority);

      logger.info('Fetched free atsign: $atsign');
      result.data['atsign'] = atsign;
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
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
