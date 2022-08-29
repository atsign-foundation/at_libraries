import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:args/args.dart';
import 'dart:io';

void main(List<String> arguments) async {
  //defaults
  String rootServer = 'root.atsign.org';

  //get atSign and CRAM key from args
  final parser = ArgParser()
    ..addOption('atsign', abbr: 'a', help: 'atSign to activate')
    ..addOption('cramkey', abbr: 'c', help: 'CRAM key')
    ..addFlag('help', abbr: 'h', help: 'Usage instructions', negatable: false)
    ..addFlag('staging',
        abbr: 's', help: 'Use staging root server', negatable: false);

  ArgResults argResults = parser.parse(arguments);

  if (argResults.wasParsed('help')) {
    print(parser.usage);
    exit(0);
  }

  if (!argResults.wasParsed('atsign')) {
    stderr.writeln(
        '--atsign (or -a) is required. Run with --help (or -h) for more.');
    exit(1);
  }

  if (!argResults.wasParsed('cramkey')) {
    stderr.writeln(
        '--cramkey (or -c) is required. Run with --help (or -h) for more.');
    exit(2);
  }

  if (!argResults.wasParsed('staging')) {
    stdout.writeln('Root server is default ' + rootServer);
  } else {
    rootServer = 'root.atsign.wtf';
    stdout.writeln('Root server is staging ' + rootServer);
  }

  //onboarding preference builder can be used to set onboardingService parameters
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = rootServer
    ..cramSecret = argResults['cramkey']
    ..downloadPath = '${Directory.current.path}/keys';

  //onboard the atSign
  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl(argResults['atsign'], atOnboardingPreference);

  await onboardingService.onboard();

  await onboardingService.close();
  //free the object after it's used and no longer required
  onboardingService = null;
}