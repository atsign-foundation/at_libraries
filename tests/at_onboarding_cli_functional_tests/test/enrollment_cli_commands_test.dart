import 'dart:io';

import 'package:at_auth/at_auth.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/cli/auth_cli.dart' as auth_cli;
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';

void main() {
  String atSign = '@sitaram🛠';
  String apkamKeysFilePath = 'storage/keys/@sitaram-apkam.atKeys';
  final logger = AtSignLogger('E2E Test');

  group('A group of tests to validate enrollment commands', () {
    /// The test verifies the following scenario's
    /// 1. Onboards an atSign
    /// 2. Sets Semi Permanent Passcode
    /// 3. Submits an enrollment request
    /// 4. Approves the enrollment request
    /// 5. Performs authentication with the approved enrollment Id. Authentication should be successful.
    /// 6. Revokes the enrollment Id.
    /// 7. Performs authentication again with the revoked enrollment Id. Authentication fails this time.
    /// 8. Unrevoke the enrollment Id.
    /// 9. Performs authentication again with the unrevoked enrollment Id. Authentication should be successful.
    test(
        'A test to verify end-to-end flow of approve revoke unrevoke of an enrollment',
        () async {
      AtOnboardingService atOnboardingService = AtOnboardingServiceImpl(
          atSign,
          getOnboardingPreference(atSign,
              '${Platform.environment['HOME']}/.atsign/keys/${atSign}_key.atKeys')
            // Fetched cram key from the at_demos repo.
            ..cramSecret =
                '15cdce8f92bcf7e742d5b75dc51ec06d798952f8bf7e8ff4c2b6448e5f7c2c12b570fe945f04011455fdc49cacdf9393d9c1ac4609ec71c1a0b0c213578e7ec7');

      bool onboardingStatus = await atOnboardingService.onboard();
      expect(onboardingStatus, true);
      // Set SPP
      List<String> args = [
        'spp',
        '-s',
        'ABC123',
        '-a',
        atSign,
        '-r',
        'vip.ve.atsign.zone'
      ];
      var res = await auth_cli.wrappedMain(args);
      // Zero indicates successful completion.
      expect(res, 0);

      // Submit enrollment request
      AtEnrollmentResponse atEnrollmentResponse = await atOnboardingService
          .sendEnrollRequest(
              'wavi', 'local-device', 'ABC123', {'e2etest': 'rw'});
      logger.info(
          'Submitted enrollment successfully with enrollmentId: ${atEnrollmentResponse.enrollmentId}');
      expect(atEnrollmentResponse.enrollStatus, EnrollmentStatus.pending);
      expect(atEnrollmentResponse.enrollmentId.isNotEmpty, true);

      // Approve enrollment request
      args = [
        'approve',
        '-a',
        atSign,
        '-r',
        'vip.ve.atsign.zone',
        '-i',
        atEnrollmentResponse.enrollmentId
      ];
      res = await auth_cli.wrappedMain(args);
      expect(res, 0);
      logger.info(
          'Approved enrollment with enrollmentId: ${atEnrollmentResponse.enrollmentId}');

      // Generate Atkeys file for the enrollment request.
      await atOnboardingService.awaitApproval(atEnrollmentResponse);
      await atOnboardingService.createAtKeysFile(atEnrollmentResponse,
          atKeysFile: File(apkamKeysFilePath));

      // Authenticate with APKAM keys
      atOnboardingService = AtOnboardingServiceImpl(
          atSign, getOnboardingPreference(atSign, apkamKeysFilePath));
      bool authResponse = await atOnboardingService.authenticate(
          enrollmentId: atEnrollmentResponse.enrollmentId);
      expect(authResponse, true);

      // Revoke the enrollment
      args = [
        'revoke',
        '-a',
        atSign,
        '-r',
        'vip.ve.atsign.zone',
        '-i',
        atEnrollmentResponse.enrollmentId
      ];
      res = await auth_cli.wrappedMain(args);
      expect(res, 0);
      logger.info(
          'Revoked enrollment with enrollmentId: ${atEnrollmentResponse.enrollmentId}');

      // Perform authentication with revoked enrollmentId
      expect(
          () async => await atOnboardingService.authenticate(
              enrollmentId: atEnrollmentResponse.enrollmentId),
          throwsA(predicate((dynamic e) => e is AtAuthenticationException)));

      // UnRevoke the enrollment
      args = [
        'unrevoke',
        '-a',
        atSign,
        '-r',
        'vip.ve.atsign.zone',
        '-i',
        atEnrollmentResponse.enrollmentId
      ];
      res = await auth_cli.wrappedMain(args);
      logger.info(
          'Un-Revoked enrollment with enrollmentId: ${atEnrollmentResponse.enrollmentId}');
      // Perform authentication with the unrevoked enrollment-id.
      authResponse = await atOnboardingService.authenticate(
          enrollmentId: atEnrollmentResponse.enrollmentId);
      expect(authResponse, true);
    });
  });

  tearDown(() {
    File file = File(apkamKeysFilePath);
    file.deleteSync();
  });
}

AtOnboardingPreference getOnboardingPreference(
    String atSign, String atKeysFilePath) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace = 'buzz'
    ..atKeysFilePath = atKeysFilePath
    ..appName = 'buzz'
    ..deviceName = 'iphone'
    ..rootDomain = 'vip.ve.atsign.zone';

  return atOnboardingPreference;
}
