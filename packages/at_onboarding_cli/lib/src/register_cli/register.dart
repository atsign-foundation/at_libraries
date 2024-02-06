import 'dart:io';

import 'package:args/args.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/activate_cli/activate_cli.dart'
    as activate_cli;
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_register/at_register.dart';

///Class containing logic to register a free atsign to email provided
///through [args] by utilizing methods defined in [RegisterUtil]
///Requires List<String> args containing the following arguments: email
class Register {
  Future<void> main(List<String> args) async {
    RegisterParams registerParams = RegisterParams();
    RegistrarApiCalls registerUtil = RegistrarApiCalls();

    final argParser = ArgParser()
      ..addOption('email',
          abbr: 'e',
          help: 'The email address you would like to assign your atSign to')
      ..addFlag('help',
          abbr: 'h', help: 'Usage instructions', negatable: false);

    ArgResults argResults = argParser.parse(args);

    if (argResults.wasParsed('help')) {
      stderr.writeln(
          '[Usage] dart run register.dart -e email@email.com\n[Options]\n${argParser.usage}');
      exit(0);
    }

    if (!argResults.wasParsed('email')) {
      stderr.writeln(
          '[Unable to run Register CLI] Please enter your email address'
          '\n[Usage] dart run register.dart -e email@email.com\n[Options]\n${argParser.usage}');
      exit(6);
    }

    if (ApiUtil.validateEmail(argResults['email'])) {
      registerParams.email = argResults['email'];
    } else {
      stderr.writeln(
          '[Unable to run Register CLI] You have entered an invalid email address. Check your email address and try again.');
      exit(7);
    }

    // create a queue of tasks each of type [RegisterTask] and then
    // call start on the RegistrationFlow object
    await RegistrationFlow(registerParams, registerUtil)
        .add(GetFreeAtsign())
        .add(RegisterAtsign())
        .add(ValidateOtp())
        .start();

    activate_cli
        .main(['-a', registerParams.atsign!, '-c', registerParams.cram!]);
  }
}

Future<void> main(List<String> args) async {
  Register register = Register();
  AtSignLogger.root_level = 'severe';
  try {
    await register.main(args);
  } on MaximumAtsignQuotaException {
    stdout.writeln(
        '[Unable to proceed] This email address already has 10 free atSigns associated with it.\n'
        'To register a new atSign to this email address, please log into the dashboard \'my.atsign.com/login\'.\n'
        'Remove at least 1 atSign from your account and then try again.\n'
        'Alternatively, you can retry this process with a different email address.');
    exit(0);
  } on FormatException catch (e) {
    if (e.toString().contains('Missing argument')) {
      stderr.writeln(
          '[Unable to run Register CLI] Please re-run with your email address');
      stderr
          .writeln('Usage: \'dart run register_cli.dart -e email@email.com\'');
      exit(1);
    } else if (e.toString().contains('Could not find an option or flag')) {
      stderr
          .writeln('[Unable to run Register CLI] The option entered is invalid.'
              ' Please use the \'-e\' flag to input your email');
      stderr
          .writeln('Usage: \'dart run register_cli.dart -e email@email.com\'');
      exit(2);
    } else {
      stderr.writeln(
          '[Error] Failed getting an atsign. It looks like something went wrong on our side.\n'
          'Please try again or contact support@atsign.com, quoting the text displayed below.');
      stderr.writeln('Cause: $e');
      exit(3);
    }
  } on AtException catch (e) {
    stderr.writeln(
        '[Error] Failed getting an atsign. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com, quoting the text displayed below.');
    stderr.writeln('Cause: ${e.message}  ExceptionType:${e.runtimeType}');
    exit(4);
  } on Exception catch (e) {
    if (e
        .toString()
        .contains('Incorrect otp entered 3 times. Max retries reached.')) {
      stderr.writeln(
          '[Unable to proceed] Registration has been terminated as you have'
          ' reached the maximum number of verification attempts.\n'
          'Please start again or contact support@atsign.com');
      exit(5);
    } else {
      stderr.writeln(
          '[Error] Failed getting an atsign. It looks like something went wrong on our side.\n'
          'Please try again or contact support@atsign.com, quoting the text displayed below.');
      stderr.writeln('Cause: ${e.toString()}');
      exit(6);
    }
  }
}
