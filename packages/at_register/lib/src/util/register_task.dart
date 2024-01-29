import 'dart:collection';

import 'package:at_register/at_register.dart';
import 'package:at_register/src/util/register_result.dart';

/// Represents a task in an AtSign registration cycle
abstract class RegisterTask {
  static final maximumRetries = 3;

  int retryCount = 1;

  late Map<String, String> params;

  late OnboardingUtil registerUtil;

  RegisterResult result = RegisterResult();

  ///Initializes the Task object with necessary parameters
  ///[params] is a map that contains necessary data to complete atsign
  ///                    registration process
  void init(Map<String, String> params, OnboardingUtil registerUtil) {
    this.params = params;
    result.data = HashMap<String, String>();
    this.registerUtil = registerUtil;
  }

  ///Implementing classes need to implement required logic in this method to
  ///complete their sub-process in the AtSign registration process
  Future<RegisterResult> run();

  ///In case the task has returned a [RegisterResult] with status retry, this method checks and returns if the call can be retried
  bool shouldRetry() {
    return retryCount < maximumRetries;
  }
}
