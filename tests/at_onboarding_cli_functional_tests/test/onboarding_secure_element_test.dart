import 'package:at_chops/at_chops.dart';
import 'package:at_chops/at_chops_secure_element.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

/// Usage: dart main.dart <cram_secret>
Future<void> main() async {
  final atSign = '@bob';

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
    ..atKeysFilePath = 'storage/files/@bob_key.atKeys'
    ..useAtChops = true
    ..signingAlgoType = SigningAlgoType.ecc_secp256r1
    ..hashingAlgoType = HashingAlgoType.sha256
    ..authMode = PkamAuthMode.sim
    ..publicKeyId = '3023020'
    ..cramSecret =
        '33c2df30b79743ff880fc1c832a5c69170974dd736231b84ee360df89a0faff1f6efe0e83064144a7b4e5029334ad1daedc49bf82c0be1f763f590c28e33ba0a'
    ..skipSync = true;
  AtSignLogger.root_level = 'FINER';
  var logger = AtSignLogger('OnboardSecureElement');

  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl(atSign, atOnboardingConfig);
  // create empty keys in atchops. Encryption key pair will be set later on after generation
  onboardingService.atChops =
      AtChopsSecureElement(AtChopsKeys.create(null, null));
  (onboardingService.atChops as AtChopsSecureElement).init();
  logger.info('calling onboard');
  await onboardingService.onboard();
  logger.info('onboard done');
  logger.info('calling auth');
  await onboardingService.authenticate();
  logger.info('auth done');
}
