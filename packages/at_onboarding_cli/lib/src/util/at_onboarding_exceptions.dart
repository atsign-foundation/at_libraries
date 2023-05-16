import 'package:at_client/at_client.dart';

class AtOnboardingException extends AtClientException{
  AtOnboardingException(message,
      {Intent? intent, ExceptionScenario? exceptionScenario})
      : super.message(message, intent: intent, exceptionScenario: exceptionScenario);
}

class AtActivateException extends AtOnboardingException{
  AtActivateException(message, {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

class AtAuthenticationFailureException extends AtOnboardingException{
  AtAuthenticationFailureException(message, {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

class InvalidResourceException extends AtOnboardingException{
  InvalidResourceException(message, {Intent? intent, ExceptionScenario? exceptionScenario})
      : super(message, intent: intent, exceptionScenario: exceptionScenario);
}

