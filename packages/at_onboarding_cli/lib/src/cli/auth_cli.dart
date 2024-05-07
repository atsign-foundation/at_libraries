import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:args/args.dart';
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_onboarding_cli/src/util/print_full_parser_usage.dart';
import 'dart:io';
import 'package:at_utils/at_utils.dart';
import 'package:meta/meta.dart';

import 'auth_cli_args.dart';
import 'auth_cli_arg_validation.dart';

final AtSignLogger logger = AtSignLogger(' CLI ');

final aca = AuthCliArgs();

Future<int> main(List<String> arguments) async {
  AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;
  try {
    return await _main(arguments);
  } on ArgumentError catch (e) {
    stderr.writeln('Invalid argument: ${e.message}');
    aca.parser.printAllCommandsUsage();
    return 1;
  } catch (e) {
    stderr.writeln('Error: $e');
    aca.parser.printAllCommandsUsage();
    return 1;
  }
}

Future<int> _main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln('You must supply a command.');
    aca.parser.printAllCommandsUsage(showSubCommandParams: false);
    stderr.writeln('\n'
        'Use --help or -h flag to show full usage of all commands'
        '\n');
    return 1;
  }

  final first = arguments.first;
  if (first.startsWith('-') && first != '-h' && first != '--help') {
    // no command found ... legacy ... insert 'onboard' as the command
    arguments = ['onboard', ...arguments];
  }

  final ArgResults topLevelResults = aca.parser.parse(arguments);

  if (topLevelResults.wasParsed(AuthCliArgs.argNameHelp)) {
    aca.sharedArgsParser
        .printAllCommandsUsage(header: 'Arguments common to all commands: ');
    aca.parser.printAllCommandsUsage(showSubCommandParams: true);
    stderr.writeln();
    return 0;
  }

  final AuthCliCommand cliCommand;
  try {
    cliCommand = AuthCliCommand.values.byName(arguments.first);
  } catch (e) {
    throw ArgumentError('Unknown command: ${arguments.first}');
  }

  if (topLevelResults.command == null) {
    throw ArgumentError('No command was parsed');
  }

  ArgResults commandArgResults = topLevelResults.command!;
  if (commandArgResults.name != cliCommand.name) {
    throw ArgumentError('detected command ${cliCommand.name}'
        ' but parsed command ${commandArgResults.name} ');
  }

  // Parse the command options
  ArgParser commandParser = aca.parser.commands[cliCommand.name]!;

  if (commandArgResults.wasParsed(AuthCliArgs.argNameHelp)) {
    commandParser.printAllCommandsUsage(
        header: 'Usage: ${cliCommand.name}', showSubCommandParams: true);
    aca.sharedArgsParser.printAllCommandsUsage();
    stderr.writeln('\n${cliCommand.usage}\n');
    return 0;
  }

  // Parse the log levels and act accordingly
  AtSignLogger.root_level = 'warning';

  if (commandArgResults.wasParsed(AuthCliArgs.argNameVerbose)) {
    AtSignLogger.root_level = 'info';
  }
  if (commandArgResults.wasParsed(AuthCliArgs.argNameDebug)) {
    AtSignLogger.root_level = 'finest';
  }

  // Execute the command
  try {
    switch (cliCommand) {
      case AuthCliCommand.help:
        aca.parser.printAllCommandsUsage(showSubCommandParams: true);
        break;

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
        await setSpp(
            commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.otp:
        // generate a one-time-passcode for this atSign. This is a passcode
        // which enrolling apps can provide which will signal that this is a
        // real enrollment request and will be accepted by the atServer.
        // Note that enrollment requests always require approval from an
        // already-authenticated authorized atClient - the passcode on
        // enrollment requests is used solely to defend against ddos attacks
        // where users are bombarded with spurious enrollment requests.
        await generateOtp(
            commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.interactive:
        // Interactive session for various enrollment management activities:
        // - listing, approving, denying and revoking enrollments
        // - setting spp, generating otp, etc
        await interactive(
            commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.list:
        await list(commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.fetch:
        await fetch(commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.approve:
        await approve(
            commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.deny:
        await deny(commandArgResults, await createAtClient(commandArgResults));

      case AuthCliCommand.revoke:
        await revoke(
            commandArgResults, await createAtClient(commandArgResults));

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
      header: 'Usage: ${cliCommand.name}',
    );
    aca.sharedArgsParser.printAllCommandsUsage();
    return 1;
  } catch (e, st) {
    stderr.writeln('Error for command ${cliCommand.name}: $e');
    stderr.writeln(st);
    commandParser.printAllCommandsUsage(
      header: 'Usage: ${cliCommand.name}',
    );
    aca.sharedArgsParser.printAllCommandsUsage();
    return 1;
  }

  return 0;
}

Future<AtClient> createAtClient(ArgResults ar) async {
  String nameSpace = 'at_auth_cli';
  String atSign = AtUtils.fixAtSign(ar[AuthCliArgs.argNameAtSign]);
  CLIBase cliBase = CLIBase(
    atSign: atSign,
    atKeysFilePath: ar[AuthCliArgs.argNameAtKeys],
    nameSpace: nameSpace,
    rootDomain: ar[AuthCliArgs.argNameAtDirectoryFqdn],
    homeDir: getHomeDirectory(),
    storageDir: '${getHomeDirectory()}/.atsign/$nameSpace/$atSign/storage'
        .replaceAll('/', Platform.pathSeparator),
    verbose: ar[AuthCliArgs.argNameVerbose] || ar[AuthCliArgs.argNameDebug],
    syncDisabled: true,
    maxConnectAttempts: int.parse(ar[AuthCliArgs.argNameMaxConnectAttempts]), // 10 * 3 == 30 seconds
  );

  await cliBase.init();

  return cliBase.atClient;
}

/// When a cramSecret arg is not supplied, we first use the registrar API
/// to send an OTP to the user and then use that OTP to obtain the cram
/// secret from the registrar.
@visibleForTesting
Future<void> onboard(ArgResults argResults, {AtOnboardingService? svc}) async {
  svc ??= createOnboardingService(argResults);
  logger
      .info('Root server is ${argResults[AuthCliArgs.argNameAtDirectoryFqdn]}');
  logger.info(
      'Registrar url provided is ${argResults[AuthCliArgs.argNameRegistrarFqdn]}');

  stderr.writeln(
      '[Information] Onboarding your atSign. This may take up to 2 minutes.');
  try {
    await svc.onboard();
    logger.finest('svc.onboard() has returned - will exit(0)');
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
  svc ??= createOnboardingService(argResults);
  logger
      .info('Root server is ${argResults[AuthCliArgs.argNameAtDirectoryFqdn]}');
  logger.info(
      'Registrar url provided is ${argResults[AuthCliArgs.argNameRegistrarFqdn]}');

  if (!argResults.wasParsed(AuthCliArgs.argNameAtKeys)) {
    throw ArgumentError('The --${AuthCliArgs.argNameAtKeys} option is'
        ' mandatory for the "enroll" command');
  }
  Map<String, String> namespaces = {};
  String nsArg = argResults[AuthCliArgs.argNameNamespaceAccessList];
  List<String> nsList = nsArg.split(',');
  for (String item in nsList) {
    List<String> l = item.split(':');
    String namespace = l[0].replaceAll('"', '').trim();
    String permission = l[1].replaceAll('"', '').trim();
    namespaces[namespace] = permission;
  }
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
  } on AtEnrollmentException catch (e) {
    stderr.writeln('[Fatal] ${e.message}');
  } on AtAuthenticationException catch (e) {
    stderr.writeln('[Error] ${e.message}');
  } on Exception catch (e) {
    stderr.writeln('[Error] $e');
    stderr.writeln('[Error] Enrollment failed.\n'
        '  Cause: $e\n'
        '  Please try again or contact support@atsign.com');
  }
  logger.finest('svc.enroll() has returned');
}

@visibleForTesting
Future<void> setSpp(ArgResults argResults, AtClient atClient) async {
  String spp = argResults[AuthCliArgs.argNameSpp];
  if (invalidSpp(spp)) {
    throw ArgumentError(invalidSppMsg);
  }

  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  // send command 'otp:put:$spp'
  String? response =
      await atLookup.executeCommand('otp:put:$spp\n', auth: true);

  logger.shout('Server response: $response');
}

@visibleForTesting
Future<void> generateOtp(ArgResults argResults, AtClient atClient) async {
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  // send command 'otp:get[:ttl:$ttl]'
  String? response = await atLookup.executeCommand('otp:get\n', auth: true);
  if (response != null && response.startsWith('data:')) {
    stdout.writeln(response.substring('data:'.length));
  } else {
    logger.shout('Failed to generate OTP: server response was $response');
  }
}

/// Only usable if there are atKeys already available.
/// All commands available same as the CLI as a whole, except for
/// 'onboard' and 'enroll'
Future<void> interactive(ArgResults argResults, AtClient atClient) async {
  // TODO Factor out code which is shared between here and main()
  while (true) {
    stderr.write(r'$ ');
    List<String> arguments = stdin.readLineSync()!.split(RegExp(r'\s'));

    final AuthCliCommand cliCommand;
    try {
      cliCommand = AuthCliCommand.values.byName(arguments.first);
    } catch (e) {
      stderr.writeln('Unknown command: ${arguments.first}');
      continue;
    }

    final ArgResults topLevelResults = aca.parser.parse(arguments);

    if (topLevelResults.wasParsed(AuthCliArgs.argNameHelp)) {
      aca.sharedArgsParser
          .printAllCommandsUsage(header: 'Arguments common to all commands: ');
      aca.parser.printAllCommandsUsage(showSubCommandParams: true);
      stderr.writeln();
      continue;
    }

    if (topLevelResults.command == null) {
      stderr.writeln('No command was parsed');
      continue;
    }

    ArgResults commandArgResults = topLevelResults.command!;
    if (commandArgResults.name != cliCommand.name) {
      stderr.writeln('detected command ${cliCommand.name}'
          ' but parsed command ${commandArgResults.name} ');
      continue;
    }

    // Parse the command options
    ArgParser commandParser = aca.parser.commands[cliCommand.name]!;

    if (commandArgResults.wasParsed(AuthCliArgs.argNameHelp)) {
      commandParser.printAllCommandsUsage(
          header: 'Usage: ${cliCommand.name}', showSubCommandParams: true);
      stderr.writeln('\n${cliCommand.usage}\n');
      continue;
    }

    // Execute the command
    try {
      switch (cliCommand) {
        case AuthCliCommand.help:
          aca.parser.printAllCommandsUsage(showSubCommandParams: true);

        case AuthCliCommand.onboard:
        case AuthCliCommand.interactive:
        case AuthCliCommand.enroll:
          stderr.writeln('The "${cliCommand.name}" command'
              ' may not be used in interactive session');

        case AuthCliCommand.spp:
          await setSpp(commandArgResults, atClient);

        case AuthCliCommand.otp:
          await generateOtp(commandArgResults, atClient);

        case AuthCliCommand.list:
          await list(commandArgResults, atClient);

        case AuthCliCommand.fetch:
          await fetch(commandArgResults, atClient);

        case AuthCliCommand.approve:
          await approve(commandArgResults, atClient);

        case AuthCliCommand.deny:
          await deny(commandArgResults, atClient);

        case AuthCliCommand.revoke:
          await revoke(commandArgResults, atClient);
      }
    } on ArgumentError catch (e) {
      stderr.writeln(
          'Argument error for command ${cliCommand.name}: ${e.message}');
      commandParser.printAllCommandsUsage(header: 'Usage: ${cliCommand.name}');
    }
  }
}

Future<Map> _list(
  String? statusFilter,
  AtLookUp atLookup, {
  String? arx,
  String? drx,
}) async {
  String command = 'enroll:list';
  if (statusFilter != null) {
    command += ':{"enrollmentStatusFilter":["$statusFilter"]}';
  }
  String rawResponse = (await atLookup.executeCommand(
    '$command\n',
    auth: true,
  ))!;

  RegExp? ar;
  RegExp? dr;
  if (arx != null) {
    ar = RegExp(arx);
  }
  if (drx != null) {
    dr = RegExp(drx);
  }
  if (rawResponse.startsWith('data:')) {
    rawResponse = rawResponse.substring(rawResponse.indexOf('data:') + 5);
    Map unfiltered = jsonDecode(rawResponse);
    Map filtered = {};
    for (final String ek in unfiltered.keys) {
      final e = unfiltered[ek];
      String appName = e['appName'] as String;
      if (ar != null) {
        if (!ar.hasMatch(appName)) {
          continue;
        }
      }
      String deviceName = e['deviceName'] as String;
      if (dr != null) {
        if (!dr.hasMatch(deviceName)) {
          continue;
        }
      }
      filtered[ek.substring(0, ek.indexOf('.'))] = e;
    }
    logger.shout("Found ${filtered.length} matching enrollment records");
    return filtered;
  } else {
    logger.shout('Exiting: Unexpected server response: $rawResponse');
    exit(1);
  }
}

Future<void> list(ArgResults ar, AtClient atClient) async {
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  String? statusFilter = ar[AuthCliArgs.argNameEnrollmentStatus];
  String? arx = ar[AuthCliArgs.argNameAppNameRegex];
  String? drx = ar[AuthCliArgs.argNameDeviceNameRegex];

  Map json = await _list(statusFilter, atLookup, arx: arx, drx: drx);
  stdout.write('Enrollment ID'.padRight(38));
  stdout.write('Status'.padRight(10));
  stdout.write('AppName'.padRight(20));
  stdout.write('DeviceName'.padRight(38));
  stdout.writeln('Namespaces');
  for (final eId in json.keys) {
    final e = json[eId] as Map;
    final String status = e['status'];
    final String appName = e['appName'];
    final String deviceName = e['deviceName'];
    final namespaces = e['namespace'];
    stdout.writeln('${eId.padRight(38)}'
        '${status.padRight(10)}'
        '${appName.padRight(20)}'
        '${deviceName.padRight(38)}'
        '$namespaces');
  }
}

Future<Map?> _fetch(String eId, AtLookUp atLookup) async {
  String rawResponse = (await atLookup.executeCommand(
      'enroll:fetch:'
      '{"enrollmentId":"$eId"}'
      '\n',
      auth: true))!;

  if (rawResponse.startsWith('data:')) {
    rawResponse = rawResponse.substring(rawResponse.indexOf('data:') + 5);
    // response is a Map
    return jsonDecode(rawResponse);
  } else {
    logger.shout('Exiting: Unexpected server response: $rawResponse');
    exit(1);
  }
}

Future<void> fetch(ArgResults argResults, AtClient atClient) async {
  String eId = argResults[AuthCliArgs.argNameEnrollmentId];
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  Map? er = await _fetch(eId, atLookup);
  if (er == null) {
    logger.shout('Enrollment ID $eId not found');
    return;
  } else {
    stderr.writeln('Fetched enrollment OK: $er');
  }
}

Future<Map> _fetchOrListAndFilter(
  AtLookUp atLookup,
  String statusFilter, {
  String? eId,
  String? arx,
  String? drx,
}) async {
  if (eId == null && arx == null && drx == null) {
    throw ArgumentError('At least one of'
        ' --${AuthCliArgs.argNameEnrollmentId},'
        ' --${AuthCliArgs.argNameAppNameRegex}'
        ' or --${AuthCliArgs.argNameDeviceNameRegex}'
        ' must be provided');
  }

  Map enrollmentMap = {};
  if (eId != null) {
    // First fetch the enrollment request
    Map? er = await _fetch(eId, atLookup);
    if (er == null) {
      logger.shout('Enrollment ID $eId not found');
    }
    enrollmentMap[eId] = er;
  } else {
    enrollmentMap = await _list(
      statusFilter,
      atLookup,
      arx: arx,
      drx: drx,
    );
  }
  return enrollmentMap;
}

Future<void> approve(ArgResults ar, AtClient atClient) async {
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  Map toApprove = await _fetchOrListAndFilter(
    atLookup,
    EnrollmentStatus.pending.name, // must be status pending
    eId: ar[AuthCliArgs.argNameEnrollmentId],
    arx: ar[AuthCliArgs.argNameAppNameRegex],
    drx: ar[AuthCliArgs.argNameDeviceNameRegex],
  );

  if (toApprove.isEmpty) {
    logger.shout('No matching enrollment(s) found');
    return;
  }

  // Iterate through the requests, approve each one
  for (String eId in toApprove.keys) {
    Map er = toApprove[eId];
    logger.shout('Approving enrollmentId $eId');
    // Then make a 'decision' object using data from the enrollment request
    EnrollmentRequestDecision decision = EnrollmentRequestDecision.approved(
        ApprovedRequestDecisionBuilder(
            enrollmentId: eId,
            encryptedAPKAMSymmetricKey: er['encryptedAPKAMSymmetricKey']));

    // Finally call approve method via an AtEnrollment object
    final response = await atAuthBase
        .atEnrollment(atClient.getCurrentAtSign()!)
        .approve(decision, atLookup);
    // 'enroll:approve:{"enrollmentId":"$enrollmentId"}'
    logger.shout('Server response: $response');
  }
}

Future<void> deny(ArgResults ar, AtClient atClient) async {
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  Map toDeny = await _fetchOrListAndFilter(
    atLookup,
    EnrollmentStatus.pending.name, // must be status pending
    eId: ar[AuthCliArgs.argNameEnrollmentId],
    arx: ar[AuthCliArgs.argNameAppNameRegex],
    drx: ar[AuthCliArgs.argNameDeviceNameRegex],
  );

  if (toDeny.isEmpty) {
    logger.shout('No matching enrollment(s) found');
    return;
  }

  // Iterate through the requests, deny each one
  for (String eId in toDeny.keys) {
    logger.shout('Denying enrollmentId $eId');
    // 'enroll:deny:{"enrollmentId":"$enrollmentId"}'
    String? response = await atLookup
        .executeCommand('enroll:deny:{"enrollmentId":"$eId"}\n', auth: true);
    logger.shout('Server response: $response');
  }
}

Future<void> revoke(ArgResults ar, AtClient atClient) async {
  AtLookUp atLookup = atClient.getRemoteSecondary()!.atLookUp;

  Map toRevoke = await _fetchOrListAndFilter(
    atLookup,
    EnrollmentStatus.approved.name, // must be status approved
    eId: ar[AuthCliArgs.argNameEnrollmentId],
    arx: ar[AuthCliArgs.argNameAppNameRegex],
    drx: ar[AuthCliArgs.argNameDeviceNameRegex],
  );

  if (toRevoke.isEmpty) {
    logger.shout('No matching enrollment(s) found');
    return;
  }

  // Iterate through the requests, revoke each one
  for (String eId in toRevoke.keys) {
    logger.shout('Revoking enrollmentId $eId');
    // 'enroll:revoke:{"enrollmentid":"$enrollmentId"}'
    String? response = await atLookup
        .executeCommand('enroll:revoke:{"enrollmentId":"$eId"}\n', auth: true);
    logger.shout('Server response: $response');
  }
}

@visibleForTesting
AtOnboardingService createOnboardingService(ArgResults ar) {
  String atSign = AtUtils.fixAtSign(ar[AuthCliArgs.argNameAtSign]);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = ar[AuthCliArgs.argNameAtDirectoryFqdn]
    ..registrarUrl = ar[AuthCliArgs.argNameRegistrarFqdn]
    ..cramSecret = ar[AuthCliArgs.argNameCramSecret]
    ..atKeysFilePath = ar[AuthCliArgs.argNameAtKeys];

  return AtOnboardingServiceImpl(atSign, atOnboardingPreference);
}
