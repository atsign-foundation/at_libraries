import 'dart:io';

import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_auth/at_auth.dart';
import 'package:at_client/at_client.dart';

import 'package:at_client/src/service/enrollment_service_impl.dart';

class EnrollmentOperations {
  late String atsign;
  EnrollmentService? enrollmentService;
  String storageDir = 'test/storage/temp';
  bool isAuthenticated = false;

  EnrollmentOperations(this.atsign);

  Future<String?> getOtp(String atKeysFilePath) async {
    AtOnboardingService onboardingService = AtOnboardingServiceImpl(
        atsign, getOnboardingPreference(atKeysFilePath: atKeysFilePath));
    await onboardingService.authenticate();
    String? response = await onboardingService.atClient
        ?.getRemoteSecondary()
        ?.executeCommand('otp:get\n', auth: true);
    stdout.writeln('[Test | EnrollmentOps] Fetch OTP response: $response');
    response = response?.replaceFirst('data:', '');
    await onboardingService.close(shouldExit: false);
    return response;
  }

  Future<AtEnrollmentResponse> approve(
      {required String atKeysFilePath,
      String? enrollmentId,
      String? encApkamSymmetricKey,
      String? appName,
      String? deviceName}) async {
    AtOnboardingService onboardingService = AtOnboardingServiceImpl(
        atsign, getOnboardingPreference(atKeysFilePath: atKeysFilePath));
    await onboardingService.authenticate();
    enrollmentService = EnrollmentServiceImpl(
        onboardingService.atClient!, atAuthBase.atEnrollment(atsign));

    // when enrollmentId is not provided. Fetches all enrollment requests based
    // on appName and deviceName and uses the data from the first request
    //
    // the assumption is that the first request with the given appName and deviceName
    // is the one that needs to be approved
    Enrollment? enrollment;
    if (enrollmentId == null) {
      enrollment = await fetchEnrollment(onboardingService.atClient!,
          appName: appName!, deviceName: deviceName!);
      enrollmentId = enrollment.enrollmentId;
      encApkamSymmetricKey = enrollment.encryptedAPKAMSymmetricKey;
    }
    EnrollmentRequestDecision decision = EnrollmentRequestDecision.approved(
        ApprovedRequestDecisionBuilder(
            enrollmentId: enrollmentId!,
            encryptedAPKAMSymmetricKey: encApkamSymmetricKey!));
    AtEnrollmentResponse? enrollmentResponse =
        await enrollmentService?.approve(decision);
    print('Enroll Approve Response: $enrollmentResponse');

    return enrollmentResponse!;
  }

  /// Fetches enrollment requests from server based on the [appName] and [deviceName] provided
  ///
  /// Always returns the first enrollmentId from the list fetched from server
  Future<Enrollment> fetchEnrollment(AtClient client,
      {required String appName, required String deviceName}) async {
    EnrollmentListRequestParam requestParam = EnrollmentListRequestParam()
      ..appName = appName
      ..deviceName = deviceName
      ..enrollmentListFilter = [EnrollmentStatus.pending];
    return (await enrollmentService!
        .fetchEnrollmentRequests(enrollmentListParams: requestParam))[0];
  }

  AtOnboardingPreference getOnboardingPreference(
      {String? cramKey, String? atKeysFilePath}) {
    return AtOnboardingPreference()
      ..commitLogPath = '$storageDir/commitLog/$atsign/1'
      ..hiveStoragePath = '$storageDir/hive/$atsign/1'
      ..atKeysFilePath = '$storageDir/keys/${atsign}_key.atKeys'
      ..rootDomain = 'vip.ve.atsign.zone'
      ..cramSecret = cramKey
      ..atKeysFilePath = atKeysFilePath;
  }
}
