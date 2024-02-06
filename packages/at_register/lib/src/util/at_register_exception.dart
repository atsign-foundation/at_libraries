import 'package:at_commons/at_commons.dart';

class AtRegisterException extends AtException {
  AtRegisterException(super.message, {super.intent, super.exceptionScenario});
}

class MaximumAtsignQuotaException extends AtException {
  MaximumAtsignQuotaException(super.message,
      {super.intent, super.exceptionScenario});
}

class InvalidVerificationCodeException extends AtException {
  InvalidVerificationCodeException(super.message,
      {super.intent, super.exceptionScenario});
}

class ExhaustedVerificationCodeRetriesException extends AtException {
  ExhaustedVerificationCodeRetriesException(super.message,
      {super.intent, super.exceptionScenario});
}
