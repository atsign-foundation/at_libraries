import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';
import 'package:at_utils/at_logger.dart';

import '../register_cli/registrar_api_util.dart';

abstract class OnboardingTask {
  int retryCount = 0;
  int maxRetries = 3;
  late TaskStatus taskStatus;
  late AtLookupImpl atLookup;
  late AtSignLogger logger;
  late final String? _secretKey;
  dynamic e;
  Future<dynamic> run();

  OnboardingTask(this.atLookup, this.logger, this._secretKey,
      {required this.maxRetries});

  bool shouldRetry() {
    return retryCount++ < maxRetries ? true : false;
  }

  Future<void> retry() async {
    if (shouldRetry()) {
      await run();
    } else {
      e.runtimeType == Exception
          ? throw AtOnboardingException(e)
          : AtOnboardingException(e.toString());
    }
  }
}

enum TaskStatus { success, failure }

class SetPkamPublicKey extends OnboardingTask {
  SetPkamPublicKey(AtLookupImpl atLookup, AtSignLogger logger, String secretKey)
      : super(atLookup, logger, secretKey, maxRetries: 3);

  @override
  Future<void> run() async {
    try {
      logger.finer('Updating PkamPublicKey to remote secondary');
      stdout.writeln(
          '[Information] Updating your authentication/security keys into secondary server');
      final pkamPublicKey = _secretKey;
      String updateCommand = 'update:$AT_PKAM_PUBLIC_KEY $pkamPublicKey\n';
      String? pkamUpdateResult =
          await atLookup.executeCommand(updateCommand, auth: false);
      logger.info('PkamPublicKey update result: $pkamUpdateResult');
    } on Exception catch (e) {
      logger.finer('SetPkamPublicKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('SetPkamPublicKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }
  }
}

class SetEncryptionPublicKey extends OnboardingTask {
  SetEncryptionPublicKey(
      AtLookupImpl atLookup, AtSignLogger logger, String secretKey)
      : super(atLookup, logger, secretKey, maxRetries: 3);

  @override
  Future<void> run() async {
    try {
      UpdateVerbBuilder updateBuilder = UpdateVerbBuilder()
        ..atKey = 'publickey'
        ..isPublic = true
        ..value = _secretKey;
      String? encryptKeyUpdateResult =
          await atLookup.executeVerb(updateBuilder);
      logger
          .info('Encryption public key update result $encryptKeyUpdateResult');
    } on Exception catch (e) {
      logger.finer('SetEncryptionPublicKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('SetEncryptionPublicKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }
  }
}

class DeleteCramKey extends OnboardingTask {
  DeleteCramKey(AtLookupImpl atLookup, AtSignLogger logger)
      : super(atLookup, logger, null, maxRetries: 10);

  @override
  Future<void> run() async {
    try {
      DeleteVerbBuilder deleteBuilder = DeleteVerbBuilder()
        ..atKey = AT_CRAM_SECRET;
      String? deleteResponse = await atLookup.executeVerb(deleteBuilder);
      logger.info('Cram secret delete response : $deleteResponse');
    } on Exception catch (e) {
      logger.finer('DeleteCramKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('DeleteCramKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }
  }
}

class FetchCramSecret extends OnboardingTask {
  FetchCramSecret(AtLookupImpl atLookup, AtSignLogger logger, this._atsign,
      this.registrarUrl)
      : super(atLookup, logger, null, maxRetries: 3);

  late final String? _cram;
  late final String _atsign;
  late final String registrarUrl;
  @override
  Future<String> run() async {
    try {
      _cram = await RegistrarApiUtil().getCramUsingOtp(_atsign, registrarUrl);
    } on Exception catch (e) {
      logger.finer('FetchCramKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('FetchCramKey(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }
    if (_cram == null) {
      retry();
    }
    return _cram!;
  }

  @override
  Future<void> retry() async {
    if (shouldRetry()) {
      await Future.delayed(Duration(seconds: 2));
      await run();
    } else {
      logger.info(
          'FetchCramSecret exhausted maximum retries of $retryCount | Caught: $e');
      throw AtKeyNotFoundException(
          'Could not fetch cram secret for \'$_atsign\' from registrar');
    }
  }
}

class FindSecondary extends OnboardingTask {
  SecondaryAddress? secondaryAddress;
  final String _atsign;
  SecureSocket? secureSocket;
  bool connectionFlag = false;

  FindSecondary(AtLookupImpl atLookup, AtSignLogger logger, this._atsign)
      : super(atLookup, logger, null, maxRetries: 50);

  @override
  Future<SecondaryAddress> run() async {
    try {
      secondaryAddress =
          await atLookup.secondaryAddressFinder.findSecondary(_atsign);
    } on Exception catch (e) {
      logger.finer('FindSecondary(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('FindSecondary(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }
    if (secondaryAddress == null) {
      retry();
    }
    return secondaryAddress!;
  }

  @override
  Future<void> retry() async {
    if (shouldRetry()) {
      await Future.delayed(Duration(seconds: 2));
      await run();
    } else {
      logger.info(
          'FindSecondary exhausted maximum retries of $retryCount | Caught: $e');
      throw SecondaryNotFoundException('Could not find secondary address for '
          '$_atsign after $retryCount retries. Please retry the process');
    }
  }
}

class ConnectToSecondary extends OnboardingTask {
  ConnectToSecondary(
      AtLookupImpl atLookup, AtSignLogger logger, this.secondaryAddress)
      : super(atLookup, logger, null, maxRetries: 50);

  SecureSocket? secureSocket;
  SecondaryAddress secondaryAddress;
  bool connectionFlag = false;

  @override
  Future<void> run() async {
    try {
      stdout.writeln(
          '[Information] Connecting to secondary ...$retryCount/$maxRetries');
      secureSocket = await SecureSocket.connect(
          secondaryAddress.host, secondaryAddress.port,
          timeout: Duration(
              seconds:
                  30)); // 30-second timeout should be enough even for slow networks
      connectionFlag = secureSocket?.remoteAddress != null &&
          secureSocket?.remotePort != null;
    } on Exception catch (e) {
      logger.finer('ConnectToSecondary(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    } on Error catch (e) {
      logger.finer('ConnectToSecondary(Attempt: #$retryCount) Caught: $e');
      taskStatus = TaskStatus.failure;
      this.e = e;
      retry();
    }

    if (!connectionFlag) {
      retry();
    }
  }
}
