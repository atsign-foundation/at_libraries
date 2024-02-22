import '../../at_register.dart';

/// class that handles multiple tasks of type [RegisterTask]
/// Initialized with a params map that needs to be populated with - email and api host address
/// [add] method can be used to add tasks[RegisterTask] to the [processQueue]
/// [start] needs to be called after all required tasks are added to the [processQueue]
class RegistrationFlow {
  List<RegisterTask> processQueue = [];
  RegisterTaskResult result = RegisterTaskResult();
  late RegistrarApiCalls registrarApiCall;
  RegisterParams params;

  RegistrationFlow(this.params, this.registrarApiCall);

  RegistrationFlow add(RegisterTask task) {
    processQueue.add(task);
    return this;
  }

  Future<void> start() async {
    for (RegisterTask task in processQueue) {
      task.init(params, registrarApiCall);
      result = await task.run();
      if (RegistrarConstants.isDebugMode) {
        task.logger.shout('Attempt: ${task.retryCount} | params[$params]');
        task.logger.shout('Result: $result');
      }
      if (result.apiCallStatus == ApiCallStatus.retry) {
        while (
            task.shouldRetry() && result.apiCallStatus == ApiCallStatus.retry) {
          result = await task.retry();
        }
      }
      if (result.apiCallStatus == ApiCallStatus.success) {
        params.addFromJson(result.data);
      } else {
        throw AtRegisterException(result.exceptionMessage!);
      }
    }
  }
}
