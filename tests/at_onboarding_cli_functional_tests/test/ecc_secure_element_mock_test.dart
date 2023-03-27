import 'package:at_chops/at_chops.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

import 'at_chops_secure_element_mock.dart';


/// Usage: dart main.dart <cram_secret>
Future<void> main() async {
  final atSign = '@alice';

  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    ..hiveStoragePath =
        'storage/hive'
    ..namespace = 'wavi'
    ..downloadPath =
        'storage/files'
    ..isLocalStoreRequired = true
    ..commitLogPath =
        'storage/commitLog'
    ..rootDomain = 'vip.ve.atsign.zone'
    ..fetchOfflineNotifications = true
    ..atKeysFilePath = 'storage/files/@alice_key.atKeys'
    ..useAtChops = true
    ..signingAlgoType = SigningAlgoType.ecc_secp256r1
    ..hashingAlgoType = HashingAlgoType.sha256
    ..authMode = PkamAuthMode.sim
    ..publicKeyId = '3023020'
    ..cramSecret =
        'b26455a907582760ebf35bc4847de549bc41c24b25c8b1c58d5964f7b4f8a43bc55b0e9a601c9a9657d9a8b8bbc32f88b4e38ffaca03c8710ebae1b14ca9f364'
    ..skipSync = true;
  AtSignLogger.root_level = 'FINER';
  var logger = AtSignLogger('OnboardSecureElement');

  AtOnboardingService onboardingService =
  AtOnboardingServiceImpl(atSign, atOnboardingConfig);
  // create empty keys in atchops. Encryption key pair will be set later on after generation
  final atChopsImpl = AtChopsSecureElementMock(AtChopsKeys.create(null, null));
  onboardingService.atChops = atChopsImpl;
  atChopsImpl.init();
  logger.info('calling onboard');
  await onboardingService.onboard();
  logger.info('onboard done');
  logger.info('calling auth');
  await onboardingService.authenticate();
  logger.info('auth done');
}
