import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_lookup/at_lookup.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';

var pkamPublicKey;
var pkamPrivateKey;
var encryptionPublicKey;
var encryptionPrivateKey;
var selfEncryptionKey;

final logger = AtSignLogger('OnboardingEnrollmentTest');

void main() {
  AtSignLogger.root_level = 'info';
  group('A group of tests to assert on authenticate functionality', () {
    test(
        'A test to verify send enroll request, approve enrollment and auth by enrollmentId',
        () async {
      // if onboard is testing use distinct demo atsign per test,
      // since cram keys get deleted on server for already onboarded atsign
      String atSign = '@naresh🛠';
      //1. Onboard first client
      AtOnboardingPreference preference_1 = getPreferenceForAuth(atSign);
      AtOnboardingService? onboardingService_1 =
          AtOnboardingServiceImpl(atSign, preference_1);

      logger.info('onboarding $atSign');
      bool status = await onboardingService_1.onboard();
      expect(status, true);

      preference_1.privateKey = pkamPrivateKey;
      var keysFilePath = preference_1.atKeysFilePath;
      var keysFile = File(keysFilePath!);
      expect(keysFile.existsSync(), true);
      var keysFileContent = keysFile.readAsStringSync();
      var keysFileJson = jsonDecode(keysFileContent);
      expect(keysFileJson['enrollmentId'], isNotEmpty);
      expect(keysFileJson['apkamSymmetricKey'], isNotEmpty);

      //2. authenticate first client
      logger.info('authenticating $atSign using onboarding keys');
      var authResult = await onboardingService_1.authenticate();
      expect(authResult, true);
      await _setLastReceivedNotificationDateTime(
          onboardingService_1.atClient!, atSign);

      Map<String, String> namespaces = {"buzz": "rw"};
      //3.1 test invalid otp
      String totp = 'a6b4df';
      AtOnboardingPreference enrollPreference_2 =
          getPreferenceForEnroll(atSign);
      final onboardingService_2 =
          AtOnboardingServiceImpl(atSign, enrollPreference_2);

      logger.info('trying enrollment with invalid OTP');
      await expectLater(
          onboardingService_2.enroll('buzz', 'iphone', totp, namespaces),
          throwsA(predicate((dynamic e) =>
              e is AtLookUpException &&
              e.errorCode == 'AT0011' &&
              e.errorMessage!
                  .contains('invalid otp. Cannot process enroll request'))));

      //3.2 run otp:get from first client
      logger.info('generating new OTP');
      totp = (await onboardingService_1.atClient!
          .getRemoteSecondary()!
          .executeCommand('otp:get\n', auth: true))!;
      totp = totp.replaceFirst('data:', '');
      totp = totp.trim();
      logger.info('Got new otp: $totp');

      //4.1 Start listening for notification from first client and invoke callback which approves the enrollment
      var completer = Completer<void>();

      logger
          .info('OnboardingEnrollmentTest: listening for enrollment requests');
      onboardingService_1.atClient!.notificationService
          .subscribe(regex: '.__manage')
          .listen((notification) async {
        if (completer.isCompleted) {
          return;
        }
        logger.info('OnboardingEnrollmentTest: approving request');
        await _notificationCallback(
            notification, onboardingService_1.atClient!, 'approve');
        completer.complete();
      });

      // 4.2 send enroll request for second client with valid otp
      logger.info(
          'OnboardingEnrollmentTest: sending enroll request with new OTP');
      var enrollResponse = await onboardingService_2.sendEnrollRequest(
          'buzz', 'iphone', totp, namespaces);
      logger.info('enroll response $enrollResponse');
      // enrollment id from the response
      var enrollmentId = enrollResponse.enrollmentId;
      expect(enrollmentId, isNotEmpty);
      expect(enrollResponse.enrollStatus, EnrollmentStatus.pending);

      // 4.3 Wait for the approval to happen
      logger.info('Waiting for the approval to be given');
      await completer.future;

      // 4.4 Wait for the enrolling client to successfully connect following approval
      logger.info('Waiting for the post-approval connection success');
      await onboardingService_2
          .awaitApproval(enrollResponse, retryInterval: Duration(seconds: 2))
          .timeout(Duration(seconds: 20));

      // 4.5 Wait for the enrolling client to generate its keys file
      logger.info('Creating atKeys file');
      await onboardingService_2.createAtKeysFile(enrollResponse);

      // 4.6 assert that the keys file is created for enrolled app
      logger.info('Verifying atKeys file');
      final enrolledClientKeysFile = File(enrollPreference_2.atKeysFilePath!);
      while (!await enrolledClientKeysFile.exists()) {
        logger
            .info('Sleeping for 10 seconds until atKeys file has been created');
        await Future.delayed(Duration(seconds: 10));
      }
      expect(await enrolledClientKeysFile.exists(), true);
      var enrolledClientKeysFileContent =
          enrolledClientKeysFile.readAsStringSync();
      var enrolledClientKeysFileJson =
          jsonDecode(enrolledClientKeysFileContent);
      expect(enrolledClientKeysFileJson['enrollmentId'], isNotEmpty);
      expect(enrolledClientKeysFileJson['apkamSymmetricKey'], isNotEmpty);

      // 4.7 Authenticate now with the approved enrollmentID
      logger.info('Authenticating with enrollment atKeys');
      bool authResultWithEnrollment =
          await onboardingService_2.authenticate(enrollmentId: enrollmentId);
      expect(authResultWithEnrollment, true);
      enrolledClientKeysFile.deleteSync();

      logger.info('Enroll / approve / auth test completed');
    });

    test(
        'A test to verify pkam authentication is successful when enableEnrollmentDuringOnboard flag is set to false',
        () async {
      // if onboard is testing use distinct demo atsign per test,
      // since cram keys get deleted on server for already onboarded atsign
      String atSign = '@ashish🛠';
      //1. Onboard first client
      AtOnboardingPreference preference_1 = getPreferenceForAuth(atSign);
      AtOnboardingService? onboardingService_1 =
          AtOnboardingServiceImpl(atSign, preference_1);
      bool status = await onboardingService_1.onboard();
      expect(status, true);
      preference_1.privateKey = pkamPrivateKey;

      //2. authenticate first client
      var authStatus = await onboardingService_1.authenticate();
      expect(authStatus, true);
    }, timeout: Timeout(Duration(minutes: 10)));

    test(
        'A test to verify an onboarding exception is NOT thrown'
        ' when enableEnrollmentDuringOnboard is set to true'
        ' and deviceName and appName are not passed', () async {
      // if onboard is testing use distinct demo atsign per test,
      // since cram keys get deleted on server for already onboarded atsign
      String atSign = '@colin🛠';
      // preference without appName and deviceName
      AtOnboardingPreference preference_1 = AtOnboardingPreference()
        ..rootDomain = 'vip.ve.atsign.zone'
        ..isLocalStoreRequired = true
        ..hiveStoragePath = 'storage/hive/client'
        ..commitLogPath = 'storage/hive/client/commit'
        ..cramSecret = at_demos.cramKeyMap[atSign]
        ..namespace =
            'wavi' // unique identifier that can be used to identify data from your app
        ..rootDomain = 'vip.ve.atsign.zone';

      AtOnboardingService? onboardingService_1 =
          AtOnboardingServiceImpl(atSign, preference_1);
      await onboardingService_1.onboard();
    });

    tearDown(() async {
      await tearDownFunc();
    });
  });

  test(
      'A test to verify send enroll request, deny enrollment and auth by enrollmentId should fail',
      () async {
    // if onboard is testing use distinct demo atsign per test,
    // since cram keys get deleted on server for already onboarded atsign
    String atSign = '@purnima🛠';
    //1. Onboard first client
    AtOnboardingPreference preference_1 = getPreferenceForAuth(atSign);
    AtOnboardingService? onboardingService_1 =
        AtOnboardingServiceImpl(atSign, preference_1);
    bool status = await onboardingService_1.onboard();
    expect(status, true);
    preference_1.privateKey = pkamPrivateKey;

    //2. authenticate first client
    await onboardingService_1.authenticate();
    await _setLastReceivedNotificationDateTime(
        onboardingService_1.atClient!, atSign);

    //3. run otp:get from first client
    String? totp = await onboardingService_1.atClient!
        .getRemoteSecondary()!
        .executeCommand('otp:get\n', auth: true);
    totp = totp!.replaceFirst('data:', '');
    totp = totp.trim();
    logger.finer('otp: $totp');
    Map<String, String> namespaces = {"buzz": "rw"};
    expect(totp.length, 6);
    expect(
        totp.contains('0') || totp.contains('o') || totp.contains('O'), false);
    // check whether otp contains at least one number and one alphabet
    expect(RegExp(r'^(?=.*[a-zA-Z])(?=.*\d).+$').hasMatch(totp), true);

    var completer = Completer<void>(); // Create a Completer

    //4. Subscribe to enrollment notifications; we will deny it when it arrives
    onboardingService_1.atClient!.notificationService
        .subscribe(regex: '.__manage')
        .listen(expectAsync1((notification) async {
          logger.finer('got enroll notification');
          expect(notification.value, isNotNull);
          var notificationValueJson = jsonDecode(notification.value!);
          expect(
              notificationValueJson['encryptedApkamSymmetricKey'], isNotEmpty);
          expect(notificationValueJson['appName'], 'buzz');
          expect(notificationValueJson['deviceName'], 'iphone');
          expect(notificationValueJson['namespace']['buzz'], 'rw');
          await _notificationCallback(
              notification, onboardingService_1.atClient!, 'deny');
          completer.complete();
        }, count: 1, max: -1));

    //5. enroll second client
    AtOnboardingPreference enrollPreference_2 = getPreferenceForEnroll(atSign);
    final onboardingService_2 =
        AtOnboardingServiceImpl(atSign, enrollPreference_2);

    // await expectLater(
    //     onboardingService_2.enroll(
    //       'buzz',
    //       'iphone',
    //       totp,
    //       namespaces,
    //       retryInterval: Duration(seconds: 5),
    //     ),
    //     throwsA(predicate((dynamic e) =>
    //         e is AtEnrollmentException && e.message == 'enrollment denied')));

    // quick check to verify that the fail-fast strategy change has the desired effect
    await onboardingService_2.enroll(
      'buzz',
      'iphone',
      totp,
      namespaces,
      retryInterval: Duration(seconds: 5),
    );

    await completer.future;
  });
}

Future<void> _notificationCallback(
    AtNotification notification, AtClient atClient, String response) async {
  logger.info('enroll notification received: ${notification.toString()}');
  final notificationKey = notification.key;
  final enrollmentId =
      notificationKey.substring(0, notificationKey.indexOf('.new.enrollments'));
  var enrollRequest;
  var enrollParamsJson = {};
  enrollParamsJson['enrollmentId'] = enrollmentId;
  final encryptedApkamSymmetricKey =
      jsonDecode(notification.value!)['encryptedApkamSymmetricKey'];
  var encryptionPrivateKey =
      await atClient.getLocalSecondary()!.getEncryptionPrivateKey();
  var selfEncryptionKey =
      await atClient.getLocalSecondary()!.getEncryptionSelfKey();
  final apkamSymmetricKey = EncryptionUtil.decryptKey(
      encryptedApkamSymmetricKey, encryptionPrivateKey!);
  var encryptedDefaultPrivateEncKey =
      EncryptionUtil.encryptValue(encryptionPrivateKey, apkamSymmetricKey);
  var encryptedDefaultSelfEncKey =
      EncryptionUtil.encryptValue(selfEncryptionKey!, apkamSymmetricKey);
  enrollParamsJson['encryptedDefaultEncryptionPrivateKey'] =
      encryptedDefaultPrivateEncKey;
  enrollParamsJson['encryptedDefaultSelfEncryptionKey'] =
      encryptedDefaultSelfEncKey;
  if (response == 'approve') {
    enrollRequest = 'enroll:approve:${jsonEncode(enrollParamsJson)}\n';
    logger.info('enroll approval request to server: $enrollRequest');
  } else {
    enrollRequest = 'enroll:deny:${jsonEncode(enrollParamsJson)}\n';
    logger.info('enroll denial request $enrollRequest');
  }
  String? enrollResponse = await atClient
      .getRemoteSecondary()!
      .executeCommand(enrollRequest, auth: true);
  logger.info('enroll Response from server: $enrollResponse');
  expect(enrollResponse, isNotEmpty);
  enrollResponse = enrollResponse!.replaceFirst('data:', '');
  var enrollResponseJson = jsonDecode(enrollResponse);
  if (response == 'approve') {
    expect(enrollResponseJson['status'], 'approved');
  } else {
    expect(enrollResponseJson['status'], 'denied');
  }
  expect(enrollResponseJson['enrollmentId'], enrollmentId);
}

Future<void> _setLastReceivedNotificationDateTime(
    AtClient atClient, String atSign) async {
  var lastReceivedNotificationAtKey = AtKey.local(
          'lastreceivednotification', atClient.getCurrentAtSign()!,
          namespace: atClient.getPreferences()!.namespace)
      .build();

  var atNotification = AtNotification(
      '124',
      '@bob🛠:testnotificationkey',
      atSign,
      '@bob🛠',
      DateTime.now().millisecondsSinceEpoch,
      MessageTypeEnum.text.toString(),
      true);

  await atClient.put(
      lastReceivedNotificationAtKey, jsonEncode(atNotification.toJson()));
}

AtOnboardingPreference getPreferenceForAuth(String atSign) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..rootDomain = 'vip.ve.atsign.zone'
    ..isLocalStoreRequired = true
    ..hiveStoragePath = 'storage/hive/client'
    ..commitLogPath = 'storage/hive/client/commit'
    ..cramSecret = at_demos.cramKeyMap[atSign]
    ..namespace =
        'wavi' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath =
        '${Platform.environment['HOME']}/.atsign/keys/${atSign}_key.atKeys'
    ..appName = 'wavi'
    ..deviceName = 'pixel'
    ..rootDomain = 'vip.ve.atsign.zone';

  return atOnboardingPreference;
}

AtOnboardingPreference getPreferenceForEnroll(String atSign) {
  atSign = AtUtils.fixAtSign(atSign);
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
    ..namespace =
        'buzz' // unique identifier that can be used to identify data from your app
    ..atKeysFilePath =
        '${Platform.environment['HOME']}/.atsign/keys/${atSign}_buzzkey.atKeys'
    ..appName = 'buzz'
    ..deviceName = 'iphone'
    ..rootDomain = 'vip.ve.atsign.zone';
  return atOnboardingPreference;
}

Future<void> getAtKeys(String atSign) async {
  AtOnboardingPreference preference = getPreferenceForAuth(atSign);
  String? filePath = preference.atKeysFilePath;
  var fileContents = File(filePath!).readAsStringSync();
  var keysJSON = json.decode(fileContents);
  selfEncryptionKey = keysJSON['selfEncryptionKey'];

  pkamPublicKey = EncryptionUtil.decryptValue(
      keysJSON['aesPkamPublicKey'], selfEncryptionKey);
  pkamPrivateKey = EncryptionUtil.decryptValue(
      keysJSON['aesPkamPrivateKey'], selfEncryptionKey);
  encryptionPublicKey = EncryptionUtil.decryptValue(
      keysJSON['aesEncryptPublicKey'], selfEncryptionKey);
  encryptionPrivateKey = EncryptionUtil.decryptValue(
      keysJSON['aesEncryptPrivateKey'], selfEncryptionKey);
}

Future<void> tearDownFunc() async {
  bool isExists = await Directory('storage/').exists();
  if (isExists) {
    Directory('storage/').deleteSync(recursive: true);
  }
}
