import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_logger.dart';

Future<void> main(List<String> args) async {
  AtSignLogger.root_level = 'info';
  final atSign = args[0];
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath = args[1]
    ..rootDomain = 'vip.ve.atsign.zone';
  AtOnboardingService? onboardingService = AtOnboardingServiceImpl(
      atSign, atOnboardingPreference,
      enrollmentId: _getEnrollmentIdFromKeysFile(args[1]));
  await onboardingService.authenticate(); // when authenticating
  AtLookUp? atLookup = onboardingService.atLookUp;
  AtClient? client = onboardingService.atClient;
  print(await client?.getKeys());
  print(await atLookup?.scan(regex: 'publickey'));
  await onboardingService.close();
}

String _getEnrollmentIdFromKeysFile(String keysFilePath) {
  String atAuthData = File(keysFilePath).readAsStringSync();
  final enrollmentId = jsonDecode(atAuthData)[AtConstants.enrollmentId];
  print('**** enrollmentId: $enrollmentId');
  return enrollmentId;
}
