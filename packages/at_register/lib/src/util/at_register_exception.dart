import 'package:at_commons/at_commons.dart';

class AtRegisterException extends AtException {
  AtRegisterException(String message,
      {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

class MaximumAtsignQuotaException extends AtException {
  MaximumAtsignQuotaException(String message,
      {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

class InvalidVerificationCodeException extends AtException {
  InvalidVerificationCodeException(String message,
      {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

class ExhaustedVerificationCodeRetriesException extends AtException {
  ExhaustedVerificationCodeRetriesException(String message,
      {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}
