import 'dart:io';

import 'package:args/args.dart';
import 'package:at_cli_commons/src/service_factories.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';
import 'package:chalkdart/chalk.dart';
import 'package:logging/logging.dart';
import 'package:version/version.dart';

class CLIBase {
  static final ArgParser argsParser = ArgParser()
    ..addFlag('help', negatable: false, help: 'Usage instructions')
    ..addOption('atsign',
        abbr: 'a', mandatory: true, help: 'This client\'s atSign')
    ..addOption('namespace', abbr: 'n', mandatory: true, help: 'Namespace')
    ..addOption('key-file',
        abbr: 'k',
        mandatory: false,
        help: 'Your atSign\'s atKeys file if not in ~/.atsign/keys/')
    ..addOption('cram-secret',
        abbr: 'c', mandatory: false, help: 'atSign\'s cram secret')
    ..addOption('home-dir', abbr: 'h', mandatory: false, help: 'home directory')
    ..addOption('storage-dir',
        abbr: 's',
        mandatory: false,
        help: 'directory for this client\'s local storage files')
    ..addOption('root-domain',
        abbr: 'd',
        mandatory: false,
        help: 'Root Domain',
        defaultsTo: 'root.atsign.org')
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'More logging')
    ..addFlag('never-sync', negatable: false, help: 'Do not run sync');

  final String atSign;
  final String nameSpace;
  final String rootDomain;
  final String? homeDir;
  final String? atKeysFilePath;
  final String? storageDir;
  final String? downloadDir;
  final String? cramSecret;
  final bool syncDisabled;

  late final String atKeysFilePathToUse;
  late final String localStoragePathToUse;
  late final String downloadPathToUse;

  final bool verbose;

  late final AtSignLogger logger;
  late final AtClient atClient;

  CLIBase(
      {required this.atSign,
      required this.nameSpace,
      required this.rootDomain,
      this.homeDir,
      this.verbose = false,
      this.atKeysFilePath,
      this.storageDir,
      this.downloadDir,
      this.cramSecret,
      this.syncDisabled = false}) {
    if (homeDir == null) {
      if (atKeysFilePath == null) {
        throw IllegalArgumentException(
            'homeDir must be provided when atKeysFilePath is not provided');
      }
      if (storageDir == null) {
        throw IllegalArgumentException(
            'homeDir must be provided when storageDir is not provided');
      }
      if (downloadDir == null) {
        throw IllegalArgumentException(
            'homeDir must be provided when downloadDir is not provided');
      }
    }

    atKeysFilePathToUse =
        atKeysFilePath ?? '$homeDir/.atsign/keys/${atSign}_key.atKeys';
    localStoragePathToUse =
        storageDir ?? '$homeDir/.$nameSpace/$atSign/storage';
    downloadPathToUse = downloadDir ?? '$homeDir/.$nameSpace/$atSign/files';

    AtSignLogger.defaultLoggingHandler = AtSignLogger.stdErrLoggingHandler;

    logger = AtSignLogger(runtimeType.toString());
    logger.hierarchicalLoggingEnabled = true;
    if (verbose) {
      AtSignLogger.root_level = 'INFO';
      logger.logger.level = Level.INFO;
    } else {
      AtSignLogger.root_level = 'SHOUT';
      // logger.logger.level = Level.SHOUT;
      logger.logger.level = Level.INFO;
    }
  }

  Future<void> init() async {
    AtServiceFactory? atServiceFactory;

    if (syncDisabled) {
      atServiceFactory = ServiceFactoryWithNoOpSyncService();
    }

    AtOnboardingPreference atOnboardingConfig = AtOnboardingPreference()
      ..hiveStoragePath = localStoragePathToUse
      ..namespace = nameSpace
      ..downloadPath = downloadPathToUse
      ..isLocalStoreRequired = true
      ..commitLogPath = '$localStoragePathToUse/commitLog'
      ..rootDomain = rootDomain
      ..fetchOfflineNotifications = true
      ..atKeysFilePath = atKeysFilePathToUse
      ..useAtChops = true
      ..cramSecret = cramSecret
      ..atProtocolEmitted = Version(2, 0, 0);

    AtOnboardingService onboardingService = AtOnboardingServiceImpl(
        atSign, atOnboardingConfig,
        atServiceFactory: atServiceFactory);

    if (!File(atKeysFilePathToUse).existsSync()) {
      await onboardingService.onboard();
    }

    bool authenticated = false;
    Duration retryDuration = Duration(seconds: 3);
    while (!authenticated) {
      try {
        stdout.write(chalk.brightBlue('\r\x1b[KConnecting ... '));
        await Future.delayed(Duration(
            milliseconds:
                1000)); // Pause just long enough for the retry to be visible
        authenticated = await onboardingService.authenticate();
      } catch (exception) {
        stdout.write(chalk.brightRed(
            '$exception. Will retry in ${retryDuration.inSeconds} seconds'));
      }
      if (!authenticated) {
        await Future.delayed(retryDuration);
      }
    }
    stdout.writeln(chalk.brightGreen('Connected'));

    // Get the AtClient which the onboardingService just authenticated
    atClient = AtClientManager.getInstance().atClient;
  }
}
