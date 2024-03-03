import 'package:at_register/at_register.dart';
import 'package:at_utils/at_logger.dart';

/// Represents a task in an AtSign registration cycle
abstract class RegisterTask {
  late String name;

  static final maximumRetries = 3;

  int _retryCount = 1;

  int get retryCount => _retryCount;

  late RegisterParams registerParams;

  late RegistrarApiAccessor _registrarApiAccessor;
  RegistrarApiAccessor get registrarApiAccessor => _registrarApiAccessor;

  late AtSignLogger logger;

  RegisterTask(this.registerParams,
      {RegistrarApiAccessor? registrarApiAccessorInstance}) {
    _registrarApiAccessor =
        registrarApiAccessorInstance ?? RegistrarApiAccessor();
    logger = AtSignLogger(name);
  }

  /// Implementing classes need to implement required logic in this method to
  /// complete their sub-process in the AtSign registration process
  ///
  /// If [allowRetry] is set to true, the task will rethrow all exceptions
  /// otherwise will catch the exception and store the exception message in
  /// [RegisterTaskResult.exceptionMessage]
  Future<RegisterTaskResult> run({bool allowRetry = true});

  Future<RegisterTaskResult> retry({bool allowRetry = true}) async {
    increaseRetryCount();
    return await run(allowRetry: allowRetry);
  }

  /// Increases retry count by 1
  ///
  /// This method is to ensure that retryCount cannot be reduced
  void increaseRetryCount() {
    _retryCount++;
  }

  /// In case the task has returned a [RegisterTaskResult] with status retry,
  /// this method checks and returns if the task can be retried
  bool shouldRetry() {
    return _retryCount < maximumRetries;
  }
}
