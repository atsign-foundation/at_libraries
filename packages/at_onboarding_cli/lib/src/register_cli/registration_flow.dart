import 'package:at_register/at_register.dart';

/// Processes tasks of type [RegisterTask]
/// Initialized with a params map that needs to be populated with - email and api host address
/// [add] method can be used to add tasks[RegisterTask] to the [processQueue]
/// [start] needs to be called after all required tasks are added to the [processQueue]
class RegistrationFlow {
  List<RegisterTask> processQueue = [];
  RegisterTaskResult _result = RegisterTaskResult();
  late RegisterParams params;
  String defaultExceptionMessage = 'Could not complete the task. Please retry';

  RegistrationFlow(this.params);

  RegistrationFlow add(RegisterTask task) {
    processQueue.add(task);
    return this;
  }

  Future<RegisterTaskResult> start() async {
    for (RegisterTask task in processQueue) {
      try {
        _result = await task.run(params);
        task.logger.finer('Attempt: ${task.retryCount} | params[$params]');
        task.logger.finer('Result: $_result');

        while (_result.apiCallStatus == ApiCallStatus.retry &&
            task.shouldRetry()) {
          _result = await task.retry(params);
          task.logger.finer('Attempt: ${task.retryCount} | params[$params]');
          task.logger.finer('Result: $_result');
        }
        if (_result.apiCallStatus == ApiCallStatus.success) {
          params.addFromJson(_result.data);
        } else {
          throw _result.exception ??
              AtRegisterException('${task.name}: $defaultExceptionMessage');
        }
      } on MaximumAtsignQuotaException {
        rethrow;
      } on ExhaustedVerificationCodeRetriesException {
        rethrow;
      } on InvalidVerificationCodeException {
        rethrow;
      } on AtRegisterException {
        rethrow;
      } on Exception catch (e) {
        throw AtRegisterException(e.toString());
      }
    }
    return _result;
  }
}
