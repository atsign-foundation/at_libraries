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
        // First time an app is connecting to an atServer.
        // Authenticate with cram secret
        // then set PKAM keys
        // then authenticate with PKAM to verify
        // and then delete the cram secret
        // Write keys to the usual output file @atSign_keys.atKeys
        await onboard(commandArgResults);

      case AuthCliCommand.spp:
        // set a semi-permanent passcode for this atSign. This is a passcode
        // which enrolling apps can provide which will signal that this is a
        // real enrollment request and will be accepted by the atServer.
        // Note that enrollment requests always require approval from an
        // already-authenticated authorized atClient - the passcode on
        // enrollment requests is used solely to defend against ddos attacks
        // where users are bombarded with spurious enrollment requests.
        await setSpp(commandArgResults);

      case AuthCliCommand.interactive:
        // Interactive session for various enrollment management activities:
        // - listing, approving, denying and revoking enrollments
        // - setting spp, generating otp, etc
        await interactive(commandArgResults);

      case AuthCliCommand.listen:
        // Interactive session which listens for new enrollment requests
        // and allows the user to approve or deny them.
        await listen(commandArgResults);

      case AuthCliCommand.listEnrollRequests:
        await listEnrollRequests(commandArgResults);

      case AuthCliCommand.approve:
        await approve(commandArgResults);

      case AuthCliCommand.deny:
        await deny(commandArgResults);

      case AuthCliCommand.revoke:
        await revoke(commandArgResults);

      case AuthCliCommand.enroll:
        // App which doesn't have auth keys and is not the first app.
        // Send an enrollment request which has to be approved by an existing
        // app which has permissions to approve enrollment requests.
        // Write keys to @atSign_keys.atKeys IFF it doesn't already exist; if
        // it does exist, then write to @atSign_appName_deviceName_keys.atKeys
        await enroll(commandArgResults);
    }
  } on ArgumentError catch (e) {
    stderr
        .writeln('Argument error for command ${cliCommand.name}: ${e.message}');
    commandParser.printAllCommandsUsage(
        commandName: 'Usage: ${cliCommand.name}', sink: stderr);
    return 1;
  } catch (e, st) {
    stderr.writeln('Error for command ${cliCommand.name}: $e');
    stderr.writeln(st);
    commandParser.printAllCommandsUsage(
        commandName: 'Usage: ${cliCommand.name}', sink: stderr);
    return 1;
  }

  return 0;
}

/// When a cramSecret arg is not supplied, we first use the registrar API
/// to send an OTP to the user and then use that OTP to obtain the cram
/// secret from the registrar.
@visibleForTesting
Future<void> onboard(ArgResults argResults, {AtOnboardingService? svc}) async {
  logger
      .info('Root server is ${argResults[AuthCliArgs.argNameAtDirectoryFqdn]}');
  logger.info(
      'Registrar url provided is ${argResults[AuthCliArgs.argNameRegistrarFqdn]}');

  svc ??= createOnboardingService(argResults);
  stderr.writeln(
      '[Information] Onboarding your atSign. This may take up to 2 minutes.');
  try {
    await svc.onboard();
    exit(0);
  } on InvalidDataException catch (e) {
    stderr.writeln(
        '[Error] Onboarding failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
    exit(1);
  } on InvalidRequestException catch (e) {
    stderr.writeln(
        '[Error] Onboarding failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
    exit(1);
  } on AtActivateException catch (e) {
    stderr.writeln('[Error] ${e.message}');
    exit(1);
  } on Exception catch (e) {
    stderr.writeln(
        '[Error] Onboarding failed. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com\nCause: $e');
    exit(1);
  }
}

/// auth enroll : require atSign, app name, device name, otp [, atKeys path]
///     If atKeys file doesn't exist, then this is a new enrollment
///     If it does exist, then the enrollment request has been made and we need
///         to try to auth, and act appropriately on the atServer response
@visibleForTesting
Future<void> enroll(ArgResults argResults, {AtOnboardingService? svc}) async {
  logger
      .info('Root server is ${argResults[AuthCliArgs.argNameAtDirectoryFqdn]}');
  logger.info(
      'Registrar url provided is ${argResults[AuthCliArgs.argNameRegistrarFqdn]}');

  svc ??= createOnboardingService(argResults);
  Map<String, String> namespaces = {};
  String nsArg = argResults[AuthCliArgs.argNameNamespaceAccessList];
  // TODO nsArg
  try {
    await svc.enroll(
      argResults[AuthCliArgs.argNameAppName],
      argResults[AuthCliArgs.argNameDeviceName],
      argResults[AuthCliArgs.argNamePasscode],
      namespaces,
      retryInterval: Duration(seconds: 10),
    );
  } on InvalidDataException catch (e) {
    stderr.writeln(
        '[Error] Enrollment failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on InvalidRequestException catch (e) {
    stderr.writeln(
        '[Error] Enrollment failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on AtActivateException catch (e) {
    stderr.writeln('[Error] ${e.message}');
  } on Exception catch (e) {
    stderr.writeln(
        '[Error] Enrollment failed. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com\nCause: $e');
  }
}

@visibleForTesting
Future<void> setSpp(ArgResults argResults, {AtClient? atClient}) async {
  String spp = argResults[AuthCliArgs.argNameSpp];
  if (invalidSpp(spp)) {
    throw ArgumentError(invalidSppMsg);
  }

  if (atClient == null) {
    AtOnboardingService svc = createOnboardingService(argResults);
    await svc.authenticate();
    atClient = svc.atClient!;
  }

  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  // send command 'otp:put:$spp'
  String? response = await atLookup.executeCommand('otp:put:$spp\n');
  logger.shout('Server response: $response');
}

/// Only usable if there are atKeys already available.
/// All commands available same as the CLI as a whole, except for
/// 'onboard' and 'enroll'
Future<void> interactive(ArgResults argResults) async {}

/// Only usable if there are atKeys already available.
/// Listens for notifications about new enrollment requests then prompts
/// the user to approve or deny.
Future<void> listen(ArgResults argResults) async {}

Future<void> listEnrollRequests(ArgResults argResults,
    {AtClient? atClient}) async {
  if (atClient == null) {
    AtOnboardingService svc = createOnboardingService(argResults);
    await svc.authenticate();
    atClient = svc.atClient!;
  }

  // 'enroll:list:{"enrollmentStatusFilter":["approved"]}'
  // 'enroll:list:{"enrollmentStatusFilter":["revoked"]}'
  // 'enroll:list:{"enrollmentStatusFilter":["denied"]}'
  // 'enroll:list:{"enrollmentStatusFilter":["pending"]}'
}

Future<void> approve(ArgResults argResults, {AtClient? atClient}) async {
  if (atClient == null) {
    AtOnboardingService svc = createOnboardingService(argResults);
    await svc.authenticate();
    atClient = svc.atClient!;
  }

  // 'enroll:approve:{"enrollmentId":"$secondEnrollId"}'
}

Future<void> deny(ArgResults argResults, {AtClient? atClient}) async {
  if (atClient == null) {
    AtOnboardingService svc = createOnboardingService(argResults);
    await svc.authenticate();
    atClient = svc.atClient!;
  }

  // 'enroll:deny:{"enrollmentId":"$secondEnrollId"}'
}

Future<void> revoke(ArgResults argResults, {AtClient? atClient}) async {
  if (atClient == null) {
    AtOnboardingService svc = createOnboardingService(argResults);
    await svc.authenticate();
    atClient = svc.atClient!;
  }

  // 'enroll:revoke:{"enrollmentid":"$enrollmentId"}'
}

@visibleForTesting
AtOnboardingService createOnboardingService(ArgResults ar) {
  String atSign = AtUtils.fixAtSign(ar[AuthCliArgs.argNameAtSign]);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = ar[AuthCliArgs.argNameAtDirectoryFqdn]
    ..registrarUrl = ar[AuthCliArgs.argNameRegistrarFqdn]
    ..cramSecret = ar[AuthCliArgs.argNameCramSecret];

  return AtOnboardingServiceImpl(atSign, atOnboardingPreference);
}
