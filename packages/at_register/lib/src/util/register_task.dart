import 'package:at_register/at_register.dart';
import 'package:at_utils/at_logger.dart';

/// Represents a task in an AtSign registration cycle
abstract class RegisterTask {
  late String name;

  final maximumRetries = 3;

  int _retryCount = 1;

  int get retryCount => _retryCount;

  late bool _allowRetry = false;

  late RegisterParams registerParams;

  late RegistrarApiAccessor _registrarApiAccessor;
  RegistrarApiAccessor get registrarApiAccessor => _registrarApiAccessor;

  late AtSignLogger logger;

  RegisterTask(this.registerParams,
      {RegistrarApiAccessor? registrarApiAccessorInstance,
      bool allowRetry = false}) {
    _registrarApiAccessor =
        registrarApiAccessorInstance ?? RegistrarApiAccessor();
    _allowRetry = allowRetry;
    validateInputParams();
    logger = AtSignLogger(name);
  }

  /// Implementing classes need to implement required logic in this method to
  /// complete their sub-process in the AtSign registration process
  ///
  /// If [allowRetry] is set to true, the task will rethrow all exceptions
  /// otherwise will catch the exception and store the exception message in
  /// [RegisterTaskResult.exceptionMessage]
  Future<RegisterTaskResult> run();

  Future<RegisterTaskResult> retry() async {
    increaseRetryCount();
    return await run();
  }

  bool canThrowException() {
    // cannot throw exception if retries allowed
    return !_allowRetry;
  }

  void populateApiCallStatus(RegisterTaskResult result, Exception e) {
    result.apiCallStatus =
        shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    result.exceptionMessage = e.toString();
  }

  /// Each task implementation will have a set of params that are required to
  /// complete the respective task. This method will ensure all required params
  /// are provided/populated
  void validateInputParams();

  /// Increases retry count by 1
  ///
  /// This method is to ensure that retryCount cannot be reduced
  void increaseRetryCount() {
    _retryCount++;
  }

  /// In case the task has returned a [RegisterTaskResult] with status retry,
  /// this method checks and returns if the task can be retried
  bool shouldRetry() {
    return _retryCount <= maximumRetries;
  }
}
