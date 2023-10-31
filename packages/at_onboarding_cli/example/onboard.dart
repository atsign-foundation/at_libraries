
import 'package:args/args.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

import 'util/custom_arg_parser.dart';

Future<void> main(List<String> args) async {
  AtSignLogger.root_level = 'finest';

  ///ToDo: remove before push
  String demoCramKey =
      'b26455a907582760ebf35bc4847de549bc41c24b25c8b1c58d5964f7b4f8a43bc55b0e9a601c9a9657d9a8b8bbc32f88b4e38ffaca03c8710ebae1b14ca9f364';

  final argResults = CustomArgParser(getArgParser()).parse(args);

  final atSign = argResults['atsign'];
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..cramSecret = demoCramKey //argResults['cram']
    ..atKeysFilePath = argResults['atKeysPath']
    ..appName = 'wavi'
    ..deviceName = 'pixel'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..enableEnrollmentDuringOnboard = true;

  AtOnboardingService? onboardingService =
      AtOnboardingServiceImpl(atSign, atOnboardingPreference);
  await onboardingService.onboard();
  await onboardingService.close();
}

ArgParser getArgParser(){
  return ArgParser()
    ..addOption('atsign',
        abbr: 'a', help: 'the atsign you would like to auth with')
    ..addOption('cram', abbr: 'c', help: 'CRAM secret for the atsign')
    ..addFlag('help', abbr: 'h', help: 'Usage instructions', negatable: false);
}
