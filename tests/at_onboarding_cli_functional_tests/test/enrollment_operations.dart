import 'dart:io';

import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_auth/at_auth.dart';
import 'package:at_client/at_client.dart';

class EnrollmentOperations {
  String storageDir = '/home/srie/Desktop/temp';
  Future<String?> getOtp(String atsign, {String? atKeysFilePath}) async {
    AtOnboardingPreference preference = AtOnboardingPreference()
      ..commitLogPath = '$storageDir/commitLog/$atsign/1'
      ..hiveStoragePath = '$storageDir/hive/$atsign/1'
      ..atKeysFilePath = atKeysFilePath
      ..rootDomain = 'vip.ve.atsign.zone';

    AtOnboardingService onboardingService =
        AtOnboardingServiceImpl(atsign, preference);
    await onboardingService.authenticate();

    String? response = await onboardingService.atClient
        ?.getRemoteSecondary()
        ?.executeCommand('otp:get\n', auth: true);
    stdout.writeln('[Test | EnrollmentOps] Fetch OTP response: $response');
    response = response?.replaceFirst('data:', '');
    onboardingService.close(shouldExit: false);

    return response;
  }

  Future<AtEnrollmentResponse> approve(String atsign,
      {String? atKeysFilePath,
      String? enrollmentId,
      String? encApkamSymmKey,
      String? appName,
      String? deviceName}) async {
    AtOnboardingPreference preference = AtOnboardingPreference()
      ..commitLogPath = '$storageDir/commitLog/$atsign/2'
      ..hiveStoragePath = '$storageDir/hive/$atsign/2'
      ..atKeysFilePath = atKeysFilePath
      ..rootDomain = 'vip.ve.atsign.zone';

    AtOnboardingService onboardingService =
        AtOnboardingServiceImpl(atsign, preference);
    await onboardingService.authenticate();
    // when enrollmentId is not provided. Fetches all enrollment requests based
    // on appName and deviceName and uses the enrollmentId of the first request
    enrollmentId ??= await fetchEnrollmentId(onboardingService.atClient!,
        appName: appName!, deviceName: deviceName!);

    EnrollmentRequestDecision decision = EnrollmentRequestDecision.approved(
        ApprovedRequestDecisionBuilder(
            enrollmentId: enrollmentId,
            encryptedAPKAMSymmetricKey: encApkamSymmKey!));
    AtEnrollmentResponse enrollmentResponse = await atAuthBase
        .atEnrollment(atsign)
        .approve(decision, onboardingService.atLookUp!);
    print('Enroll Approve Response: $enrollmentResponse');
    onboardingService.close(shouldExit: false);

    return enrollmentResponse;
  }

  /// Fetches enrollment requests from server based on the [appName] and [deviceName] provided
  ///
  /// Always returns the first enrollmentId from the list fetched from server
  Future<String> fetchEnrollmentId(AtClient client,
      {required String appName, required String deviceName}) async {
    EnrollListRequestParam requestParam = EnrollListRequestParam()
      ..appName = appName
      ..deviceName = deviceName;
    return (await client.fetchEnrollmentRequests(requestParam))[0].enrollmentId;
  }
}
