import 'package:at_commons/at_commons.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:args/args.dart';
import 'dart:io';

import 'package:at_utils/at_logger.dart';

import '../home_directory/home_directory.dart';

Future<void> main(List<String> arguments) async {
  //defaults
  String rootServer = 'root.atsign.org';
  AtSignLogger.root_level = 'severe';

  //get atSign and CRAM key from args
  final parser = ArgParser()
    ..addOption('atsign', abbr: 'a', help: 'atSign to activate')
    ..addOption('cramkey', abbr: 'c', help: 'CRAM key')
    ..addOption('qr_path', abbr: 'q', help: 'path to qr code')
    ..addOption('rootServer',
        abbr: 'r',
        help: 'root server',
        defaultsTo: rootServer,
        mandatory: false)
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

  if (!argResults.wasParsed('cramkey') && !argResults.wasParsed('qr_path')) {
    stderr.writeln(
        'Either of --cramkey(-c) or --qr_path(-q) is required. Run with --help (or -h) for more.');
    throw IllegalArgumentException('CRAM key is required');
  }

  stdout.writeln('[Information] Root server is ${argResults['rootServer']}');

  //onboarding preference builder can be used to set onboardingService parameters
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = argResults['rootServer']
    ..cramSecret = argResults['cramkey'] ??
        AtOnboardingServiceImpl.getSecretFromQr(argResults['qr_path']);

  //onboard the atSign
  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl(argResults['atsign'], atOnboardingPreference);
  stdout.writeln(
      '[Information] Activating your atSign. This may take up to 2 minutes.');
  try {
    await onboardingService.onboard();
  } on Exception catch (e) {
    stderr.writeln(
        '[Error] Activation failed. It looks like something went wrong on our side.\n'
        'Please try again or contact support@atsign.com\nCause: ${e.toString()}');
  } finally {
    await onboardingService.close();
  }
  return;
}
