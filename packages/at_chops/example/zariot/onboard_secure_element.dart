import 'dart:io';

import 'package:args/args.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_commons/at_commons.dart';

import 'at_chops_secure_element.dart';
import 'external_signer.dart';

/// Usage: dart main.dart <cram_secret>
Future<void> main(List<String> args) async {
  final atSign = '@jacstest001';
  AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
    ..hiveStoragePath = 'storage/hive'
    ..namespace = 'wavi'
    ..downloadPath = 'storage/files'
    ..isLocalStoreRequired = true
    ..commitLogPath = 'storage/commitLog'
    ..rootDomain = 'root.atsign.wtf'
    ..fetchOfflineNotifications = true
    ..atKeysFilePath = 'storage/files/@jacstest001_key.atKeys'
    ..useAtChops = true
    ..signingAlgoType = SigningAlgoType.ecc_secp256r1
    ..hashingAlgoType = HashingAlgoType.sha256
    ..authMode = PkamAuthMode.sim
    ..skipSync = true;
  AtSignLogger.root_level = 'INFO';
  var logger = AtSignLogger('OnboardSecureElement');
  var parser = ArgParser();
  parser.addOption('privateKeyId',
      abbr: 'p',
      mandatory: true,
      help: 'Private key id from sim card used to sign pkam challenge');
  parser.addOption('serialPort',
      abbr: 's',
      mandatory: false,
      defaultsTo: '/dev/ttyS0',
      help: 'serial port on which sim card is mounted');
  parser.addOption('libPeripheryLocation',
      abbr: 'l',
      mandatory: false,
      defaultsTo: '/usr/lib/arm-linux-gnueabihf/libperiphery_arm.so',
      help: 'location of native library libperiphery_arm.so');
  parser.addOption('cramSecret',
      abbr: 'c',
      mandatory: true,
      help: 'cram of the atsign from registration flow');
  dynamic results;
  try {
    results = parser.parse(args);
    atOnboardingConfig.cramSecret = results['cramSecret'];
  } catch (e) {
    print(parser.usage);
    print(e);
    exit(1);
  }
  final externalSigner = ExternalSigner();
  externalSigner.init(results['privateKeyId'], results['serialPort'],
      results['libPeripheryLocation']);
  var keyPair = externalSigner.generateKeyPair(results['privateKeyId']);
  if (keyPair == null) {
    logger.severe('Generate key pair returned null. Exiting');
    externalSigner.clear();
    exit(1);
  }
  atOnboardingConfig.publicKeyId = keyPair.publicKeyId;
  AtOnboardingService onboardingService =
      AtOnboardingServiceImpl(atSign, atOnboardingConfig);
  // create empty keys in atchops. Encryption key pair will be set later on after generation
  onboardingService.atChops =
      AtChopsSecureElement(AtChopsKeys.create(null, null))
        ..externalSigner = externalSigner;
  try {
    logger.info('calling onboard');
    await onboardingService.onboard();
    logger.info('onboard done');
    logger.info('calling auth');
    await onboardingService.authenticate();
    logger.info('auth done');
  } on Exception catch (e, trace) {
    logger.severe('exception in onboard secure element $e $trace');
  } finally {
    externalSigner.clear();
  }
}
