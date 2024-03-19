import 'package:at_auth/at_auth.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:args/args.dart';
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_onboarding_cli/src/util/print_full_parser_usage.dart';
import 'dart:io';
import 'package:at_utils/at_utils.dart';
import 'package:meta/meta.dart';

import 'cli_args.dart';
import 'cli_params_validation.dart';

final AtSignLogger logger = AtSignLogger(' CLI ');

Future<int> main(List<String> arguments) async {
  ArgParser parser = AuthCliArgs().parser;

  try {
    return await _main(parser, arguments);
  } on ArgumentError catch (e) {
    stderr.writeln('Invalid argument: ${e.message}');
    parser.printAllCommandsUsage(sink: stderr);
    return 1;
  } catch (e) {
    stderr.writeln('Error: $e');
    parser.printAllCommandsUsage(sink: stderr);
    return 1;
  }
}

Future<int> _main(ArgParser parser, List<String> arguments) async {
  if (arguments.isEmpty) {
    parser.printAllCommandsUsage(sink: stderr);
    return 0;
  }

  final first = arguments.first;
  if (first.startsWith('-') && first != '-h' && first != '--help') {
    // no command found ... legacy ... insert 'onboard' as the command
    arguments = ['onboard', ...arguments];
  }
  final AuthCliCommand cliCommand;
  try {
    cliCommand = AuthCliCommand.values.byName(arguments.first);
  } catch (e) {
    throw ArgumentError('Unknown command: ${arguments.first}');
  }

  final ArgResults topLevelResults = parser.parse(arguments);

  if (topLevelResults.wasParsed('help')) {
    parser.printAllCommandsUsage(sink: stderr);
    return 0;
  }

  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  AtSignLogger.root_level = 'warning';

  if (topLevelResults.wasParsed('verbose')) {
    AtSignLogger.root_level = 'info';
  }
  if (topLevelResults.wasParsed('debug')) {
    AtSignLogger.root_level = 'finest';
  }

  if (topLevelResults.command == null) {
    throw ArgumentError('No command was parsed');
  }

  ArgResults commandArgResults = topLevelResults.command!;
  if (commandArgResults.name != cliCommand.name) {
    throw ArgumentError('detected command ${cliCommand.name}'
        ' but parsed command ${commandArgResults.name} ');
  }

  // Execute the command

  logger.info('Chosen command: $cliCommand'
      ' with options : ${commandArgResults.arguments}'
      ' and positional args : ${commandArgResults.rest}');

  ArgParser commandParser = parser.commands[cliCommand.name]!;
  try {
    switch (cliCommand) {
      case AuthCliCommand.onboard:
        await onboard(commandArgResults);

      case AuthCliCommand.spp:
        await setSpp(commandArgResults);

      case AuthCliCommand.enroll:
        throw ('$cliCommand not yet implemented');

      case AuthCliCommand.listEnrollRequests:
        throw ('$cliCommand not yet implemented');

      case AuthCliCommand.approve:
        throw ('$cliCommand not yet implemented');

      case AuthCliCommand.deny:
        throw ('$cliCommand not yet implemented');

      case AuthCliCommand.listEnrollments:
        throw ('$cliCommand not yet implemented');

      case AuthCliCommand.revoke:
        throw ('$cliCommand not yet implemented');
    }
  } on ArgumentError catch (e) {
    stderr.writeln('Argument error for command ${cliCommand.name}: ${e.message}');
    commandParser.printAllCommandsUsage(commandName: 'Usage: ${cliCommand.name}', sink: stderr);
    return 1;
  } catch (e, st) {
    stderr.writeln('Error for command ${cliCommand.name}: $e');
    stderr.writeln(st);
    commandParser.printAllCommandsUsage(commandName: 'Usage: ${cliCommand.name}', sink: stderr);
    return 1;
  }

  return 0;
}

/// onboard params: atSign, [, cram, atDirectory, atRegistrar]
/// When a cram arg is not supplied, we first use the registrar API
/// to send an OTP to the user and then use that OTP to obtain the cram
/// secret from the registrar.
@visibleForTesting
Future<void> onboard(ArgResults argResults,
    {AtOnboardingService? atOnboardingService}) async {
  logger.info('Root server is ${argResults['rootServer']}');
  logger.info('Registrar url provided is ${argResults['registrarUrl']}');

  atOnboardingService ??= createOnboardingService(
    atSign: argResults['atsign'],
    atDirectoryFqdn: argResults['rootServer'],
    atRegistrarFqdn: argResults['registrarUrl'],
    cramSecret: argResults['cramkey'],
  );

  stderr.writeln(
      '[Information] Activating your atSign. This may take up to 2 minutes.');
  try {
    await atOnboardingService.onboard();
  } on InvalidDataException catch (e) {
    stderr.writeln(
        '[Error] Activation failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on InvalidRequestException catch (e) {
    stderr.writeln(
        '[Error] Activation failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on AtActivateException catch (e) {
    stderr.writeln('[Error] ${e.message}');
  } on Exception catch (e) {
    stderr.writeln(
        '[Error] Activation failed. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com\nCause: $e');
  } finally {
    await atOnboardingService.close();
  }
}

@visibleForTesting
Future<void> setSpp(
  ArgResults argResults, {
  AtOnboardingService? svc,
}) async {
  String atSign = argResults['atsign'];
  String spp = argResults['spp'];

  atSign = AtUtils.fixAtSign(atSign);

  if (invalidSpp(spp)) {
    throw ArgumentError(invalidSppMsg);
  }

  svc ??= createOnboardingService(
    atSign: argResults['atsign'],
    atDirectoryFqdn: argResults['rootServer'],
  );

  // authenticate
  await svc.authenticate();

  AtClient atClient = svc.atClient!;
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;
  AtChops atChops = atClient.atChops!;
  AtAuth atAuth = svc.atAuth!;

  // send command 'otp:put:$spp'
  String? response = await atLookup.executeCommand('otp:put:$spp\n');
  logger.shout('Server response: $response');
}

@visibleForTesting
AtOnboardingService createOnboardingService({required String atSign, String atDirectoryFqdn = AuthCliArgs.defaultAtDirectoryFqdn, String atRegistrarFqdn = AuthCliArgs.defaultAtRegistrarFqdn, String? cramSecret}) {
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = atDirectoryFqdn
    ..registrarUrl = atRegistrarFqdn
    ..cramSecret = cramSecret
    ..useAtChops = true;

  return AtOnboardingServiceImpl(atSign, atOnboardingPreference);
}