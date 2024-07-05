import 'dart:io';

import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_auth/at_auth.dart';
import 'package:at_client/at_client.dart';

import 'package:at_client/src/service/enrollment_service_impl.dart';

class EnrollmentOperations {
  late String atsign;
  EnrollmentService? enrollmentService;
  String storageDir = 'test/testStorage/temp';
  AtOnboardingService? onboardingService;
  bool isAuthenticated = false;

  EnrollmentOperations(this.atsign);

  void initOnboardingService({String? cramKey}) {
    AtOnboardingPreference preference = AtOnboardingPreference()
      ..commitLogPath = '$storageDir/commitLog/$atsign/1'
      ..hiveStoragePath = '$storageDir/hive/$atsign/1'
      ..atKeysFilePath = '$storageDir/keys/${atsign}_key.atKeys'
      ..rootDomain = 'vip.ve.atsign.zone'
      ..cramSecret = cramKey;

    onboardingService = AtOnboardingServiceImpl(atsign, preference);
  }

  Future<bool> onboard({required String cramKey}) async {
    initOnboardingService(cramKey: cramKey);
    return await onboardingService!.onboard();
  }

  Future<String?> getOtp() async {
    if (onboardingService == null) {
      initOnboardingService();
    }
    if (!isAuthenticated) {
      isAuthenticated = await onboardingService!.authenticate();
    }

    String? response = await onboardingService?.atClient
        ?.getRemoteSecondary()
        ?.executeCommand('otp:get\n', auth: true);
    stdout.writeln('[Test | EnrollmentOps] Fetch OTP response: $response');
    response = response?.replaceFirst('data:', '');

    return response;
  }

  Future<AtEnrollmentResponse> approve(
      {String? enrollmentId,
      String? encApkamSymmKey,
      String? appName,
      String? deviceName}) async {
    if (onboardingService == null) {
      initOnboardingService();
    }
    if (!isAuthenticated) {
      isAuthenticated = await onboardingService!.authenticate();
    }
    enrollmentService = EnrollmentServiceImpl(
        onboardingService!.atClient!, atAuthBase.atEnrollment(atsign));
    // when enrollmentId is not provided. Fetches all enrollment requests based
    // on appName and deviceName and uses the enrollmentId of the first request
    enrollmentId ??= await fetchEnrollmentId(onboardingService!.atClient!,
        appName: appName!, deviceName: deviceName!);

    EnrollmentRequestDecision decision = EnrollmentRequestDecision.approved(
        ApprovedRequestDecisionBuilder(
            enrollmentId: enrollmentId!,
            encryptedAPKAMSymmetricKey: encApkamSymmKey!));
    AtEnrollmentResponse? enrollmentResponse =
        await enrollmentService?.approve(decision);
    print('Enroll Approve Response: $enrollmentResponse');

    return enrollmentResponse!;
  }

  /// Fetches enrollment requests from server based on the [appName] and [deviceName] provided
  ///
  /// Always returns the first enrollmentId from the list fetched from server
  Future<String?> fetchEnrollmentId(AtClient client,
      {required String appName, required String deviceName}) async {
    EnrollmentListRequestParam requestParam = EnrollmentListRequestParam()
      ..appName = appName
      ..deviceName = deviceName;
      // ..enrollmentListFilter = [EnrollmentStatus.pending];
    return (await enrollmentService!
            .fetchEnrollmentRequests(enrollmentListParams: requestParam))[0]
        .enrollmentId;
  }
}
