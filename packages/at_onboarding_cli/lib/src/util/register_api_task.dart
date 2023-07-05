import 'dart:collection';

import 'package:at_onboarding_cli/src/util/register_api_result.dart';
import 'package:at_onboarding_cli/src/register_cli/registrar_api_util.dart';

/// Represents a task in an AtSign registration cycle
abstract class RegisterApiTask {
  static final maximumRetries = 3;

  int retryCount = 1;

  late Map<String, String> params;

  late RegistrarApiUtil registrarApiUtil;

  RegisterApiResult result = RegisterApiResult();

  ///Initializes the Task object with necessary parameters
  ///[params] is a map that contains necessary data to complete atsign
  ///                    registration process
  void init(Map<String, String> params, RegistrarApiUtil onboardingUtil) {
    this.params = params;
    result.data = HashMap<String, String>();
    onboardingUtil = onboardingUtil;
  }

  ///Implementing classes need to implement required logic in this method to
  ///complete their sub-process in the AtSign registration process
  Future<RegisterApiResult> run();

  ///In case the task has returned a [RegisterApiResult] with status retry, this method checks and returns if the call can be retried
  bool shouldRetry() {
    return retryCount < maximumRetries;
  }
}
