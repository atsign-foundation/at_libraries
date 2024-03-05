import 'package:at_register/at_register.dart';

/// Processes tasks of type [RegisterTask]
/// Initialized with a params map that needs to be populated with - email and api host address
/// [add] method can be used to add tasks[RegisterTask] to the [processQueue]
/// [start] needs to be called after all required tasks are added to the [processQueue]
class RegistrationFlow {
  List<RegisterTask> processQueue = [];
  RegisterTaskResult _result = RegisterTaskResult();
  RegisterParams params = RegisterParams();

  RegistrationFlow();

  RegistrationFlow add(RegisterTask task) {
    processQueue.add(task);
    return this;
  }

  Future<RegisterTaskResult> start() async {
    for (RegisterTask task in processQueue) {
      // setting allowRetry to false as this method has logic to retry each
      // failed task 3-times and then throw an exception if still failing
      _result = await task.run();
      task.logger.finer('Attempt: ${task.retryCount} | params[$params]');
      task.logger.finer('Result: $_result');

      if (_result.apiCallStatus == ApiCallStatus.retry) {
        while (
            task.shouldRetry() && _result.apiCallStatus == ApiCallStatus.retry) {
          _result = await task.retry();
        }
      }
      if (_result.apiCallStatus == ApiCallStatus.success) {
        params.addFromJson(_result.data);
      } else {
        throw AtRegisterException(_result.exceptionMessage!);
      }
    }
    return _result;
  }
}
