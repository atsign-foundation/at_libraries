import '../../at_register.dart';

///This is a [RegisterTask] that fetches a list of free atsigns
///
///throws [AtException] with concerned message which was encountered in the
///HTTP GET/POST request
///
/// e.g.
///
/// `GetFreeAtsign getFreeAtsignInstance = GetFreeAtsign();`
///
/// `await getFreeAtsignInstance.init(RegisterParams(), RegistrarApiCalls());`
///
/// `RegisterTaskResult result = await getFreeAtsignInstance.run();`
///
/// atsign stored in result.data['atsign']
class GetFreeAtsign extends RegisterTask {
  @override
  String get name => 'GetFreeAtsignTask';

  @override
  Future<RegisterTaskResult> run() async {
    logger.info('Getting your randomly generated free atSign…');
    try {
      String atsign = await registrarApiCalls.getFreeAtSigns(
          authority: RegistrarConstants.authority);
      logger.info('Fetched free atsign: $atsign');
      result.data['atsign'] = atsign;
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}
