import 'dart:collection';

import 'package:at_register/at_register.dart';

/// Represents a task in an AtSign registration cycle
abstract class RegisterTask {
  static final maximumRetries = 3;

  int _retryCount = 1;

  int get retryCount => _retryCount;

  late RegisterParams registerParams;

  late RegistrarApiCalls registrarApiCalls;

  RegisterTaskResult result = RegisterTaskResult();

  /// Initializes the Task object with necessary parameters
  /// [params] is a map that contains necessary data to complete atsign
  /// registration process
  void init(RegisterParams registerParams, RegistrarApiCalls registrarApiCalls) {
    this.registerParams = registerParams;
    this.registrarApiCalls = registrarApiCalls;
    result.data = HashMap<String, String>();
  }

  /// Implementing classes need to implement required logic in this method to
  /// complete their sub-process in the AtSign registration process
  Future<RegisterTaskResult> run();

  /// Increases retry count by 1
  ///
  /// This method is to ensure that retryCount cannot be reduced
  void increaseRetryCount(){
    _retryCount++;
  }
  /// In case the task has returned a [RegisterTaskResult] with status retry,
  /// this method checks and returns if the task can be retried
  bool shouldRetry() {
    return _retryCount < maximumRetries;
  }
}
