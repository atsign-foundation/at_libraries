import 'package:at_commons/at_commons.dart';

import 'package:at_register/at_register.dart';

/// A [RegisterTask] that fetches a free atsign
///
/// Throws an [AtException] with the concerned message encountered in the
/// HTTP GET/POST request.
///
/// Example usage:
/// ```dart
/// GetFreeAtsign getFreeAtsignInstance = GetFreeAtsign();
/// RegisterTaskResult result = await getFreeAtsignInstance.run(registerParams);
/// ```
/// The fetched atsign will be stored in RegisterTaskResult.data[[RegistrarConstants.atsignName]]
class GetFreeAtsign extends RegisterTask {
  GetFreeAtsign(
      {RegistrarApiAccessor? apiAccessorInstance, bool allowRetry = false})
      : super(
            registrarApiAccessorInstance: apiAccessorInstance,
            allowRetry: allowRetry);

  @override
  String get name => 'GetFreeAtsignTask';

  @override
  Future<RegisterTaskResult> run(RegisterParams params) async {
    validateInputParams(params);
    logger.info('Getting a randomly generated free atSign...');
    RegisterTaskResult result = RegisterTaskResult();
    try {
      String atsign = await registrarApiAccessor.getFreeAtSign(
          authority: RegistrarConstants.authority);
      logger.info('Fetched free atsign: $atsign');
      result.data['atsign'] = atsign;
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      if (canThrowException()) {
        throw AtRegisterException(e.toString());
      }
      ApiUtil.handleException(result, e, shouldRetry());
    }
    return result;
  }

  @override
  void validateInputParams(params) {
    if (params.email.isNullOrEmpty) {
      throw IllegalArgumentException(
          'email cannot be null for get-free-atsign-task');
    }
  }
}
