import 'package:at_commons/at_commons.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:args/args.dart';
import 'dart:io';
import 'package:at_utils/at_logger.dart';

Future<void> main(List<String> arguments) async {
  //defaults
  String rootServer = 'root.atsign.org';
  String registrarUrl = 'my.atsign.com';
  AtSignLogger.root_level = 'severe';

  //get atSign and CRAM key from args
  final parser = ArgParser()
    ..addOption('atsign', abbr: 'a', help: 'atSign to activate')
    ..addOption('cramkey', abbr: 'c', help: 'CRAM key', mandatory: false)
    ..addOption('rootServer',
        abbr: 'r',
        help: 'root server\'s domain name',
        defaultsTo: rootServer,
        mandatory: false)
    ..addOption('registrarUrl',
        abbr: 'g',
        help: 'url to the registrar api',
        mandatory: false,
        defaultsTo: registrarUrl)
    ..addFlag('help', abbr: 'h', help: 'Usage instructions', negatable: false);
  ArgResults argResults = parser.parse(arguments);

  if (argResults.wasParsed('help')) {
    print(parser.usage);
    return;
  }

  if (!argResults.wasParsed('atsign')) {
    stderr.writeln(
        '--atsign (or -a) is required. Run with --help (or -h) for more.');
    throw IllegalArgumentException('atSign is required');
  }

  activate(argResults);

  exit(1);
}

Future<void> activate(ArgResults argResults,
    {AtOnboardingService? atOnboardingService}) async {
  stdout.writeln('[Information] Root server is ${argResults['rootServer']}');
  stdout.writeln(
      '[Information] Registrar url provided is ${argResults['registrarUrl']}');
  //onboarding preference builder can be used to set onboardingService parameters
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = argResults['rootServer']
    ..cramSecret =
        argResults.wasParsed('cramkey') ? argResults['cramkey'] : null;
  //onboard the atSign
  atOnboardingService ??=
      AtOnboardingServiceImpl(argResults['atsign'], atOnboardingPreference);
  stdout.writeln(
      '[Information] Activating your atSign. This may take up to 2 minutes.');
  try {
    await atOnboardingService.onboard();
  } on InvalidDataException catch (e) {
    stderr.writeln(
        '[Error] Activation failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on InvalidRequestException catch (e) {
    stderr.writeln(
        '[Error] Activation failed. Invalid data provided by user. Please try again\nCause: ${e.message}');
  } on Exception catch (e) {
    stderr.writeln(
        '[Error] Activation failed. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com\nCause: $e');
  } finally {
    await atOnboardingService.close();
  }
}
