import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_demo_data/at_demo_data.dart' as at_demos;
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_utils/at_utils.dart';
import 'package:test/test.dart';
import 'package:at_onboarding_cli/src/util/at_onboarding_exceptions.dart';

var pkamPublicKey;
var pkamPrivateKey;
var encryptionPublicKey;
var encryptionPrivateKey;
var selfEncryptionKey;
void main() {
  AtSignLogger.root_level = 'info';
  final logger = AtSignLogger('OnboardingEnrollmentTest');
  group('A group of tests to assert on authenticate functionality', () {
    test(
        'A test to verify send enroll request, approve enrollment and auth by enrollmentId',
        () async {
      // if onboard is testing use distinct demo atsign per test,
      // since cram keys get deleted on server for already onboarded atsign
      String atSign = '@naresh🛠';
      //1. Onboard first client
      AtOnboardingPreference preference_1 = getPreferenceForAuth(atSign);
      preference_1..enableEnrollmentDuringOnboard = true;
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

      //4. enroll second client
      AtOnboardingPreference enrollPreference_2 =
          getPreferenceForEnroll(atSign);
      final onboardingService_2 =
          AtOnboardingServiceImpl(atSign, enrollPreference_2);
      var enrollResponse =
          await onboardingService_2.enroll('buzz', 'iphone', totp, namespaces);
      logger.finer('enroll response $enrollResponse');
      // enrollment id from the response
      var enrollmentId = enrollResponse.enrollmentId;
      var completer = Completer<void>(); // Create a Completer

      //5. listen for notification from first client and invoke callback which approves the enrollment
      onboardingService_1.atClient!.notificationService
          .subscribe(regex: '.__manage')
          .listen(expectAsync1((notification) async {
            logger.finer('got enroll notification');
            await _notificationCallback(
                notification, onboardingService_1.atClient!, 'approve');
            completer.complete();
          }, count: 1, max: -1));
      await completer.future;

      //6. assert that the keys file is created for enrolled app
      final enrolledClientKeysFile = File(enrollPreference_2.atKeysFilePath!);
      while (!await enrolledClientKeysFile.exists()) {
        await Future.delayed(Duration(seconds: 10));
      }
      expect(await enrolledClientKeysFile.exists(), true);
      //  Authenticate now with the approved enrollmentID
      // assert that authentication is successful
      bool authResultWithEnrollment =
          await onboardingService_2.authenticate(enrollmentId: enrollmentId);
      expect(authResultWithEnrollment, true);
      enrolledClientKeysFile.deleteSync();
    }, timeout: Timeout(Duration(minutes: 3)));

    test(
        'A test to verify pkam authentication is successful when enableEnrollmentDuringOnboard flag is set to false',
        () async {
      // if onboard is testing use distinct demo atsign per test,
      // since cram keys get deleted on server for already onboarded atsign
      String atSign = '@ashish🛠';
      //1. Onboard first client
      AtOnboardingPreference preference_1 = getPreferenceForAuth(atSign);
      preference_1.enableEnrollmentDuringOnboard = false;
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
        'A test to verify an onboarding exception is thrown when enableEnrollmentDuringOnboard is set to true and deviceName and appName are not passed',
        () async {
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
        ..rootDomain = 'vip.ve.atsign.zone'
        ..enableEnrollmentDuringOnboard = true;

      AtOnboardingService? onboardingService_1 =
          AtOnboardingServiceImpl(atSign, preference_1);
      expect(
          () async => await onboardingService_1.onboard(),
          throwsA(predicate((dynamic e) =>
              e is AtOnboardingException &&
              e.message ==
                  'appName and deviceName are mandatory for onboarding. Please set the params in AtOnboardingPreference')));
    }, timeout: Timeout(Duration(minutes: 10)));

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
    preference_1.enableEnrollmentDuringOnboard = true;
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

    //4. enroll second client
    AtOnboardingPreference enrollPreference_2 = getPreferenceForEnroll(atSign);
    final onboardingService_2 =
        AtOnboardingServiceImpl(atSign, enrollPreference_2);

    var enrollResponse =
        await onboardingService_2.enroll('buzz', 'iphone', totp, namespaces);
    logger.finer('enroll response $enrollResponse');

    var completer = Completer<void>(); // Create a Completer

    //5. listen for notification from first client and invoke callback which denies the enrollment
    onboardingService_1.atClient!.notificationService
        .subscribe(regex: '.__manage')
        .listen(expectAsync1((notification) async {
          logger.finer('got enroll notification');
          await _notificationCallback(
              notification, onboardingService_1.atClient!, 'deny');
          completer.complete();
        }, count: 1, max: -1));
    await completer.future;
  }, timeout: Timeout(Duration(minutes: 5)));
}

Future<void> _notificationCallback(
    AtNotification notification, AtClient atClient, String response) async {
  print('enroll notification received: ${notification.toString()}');
  final notificationKey = notification.key;
  final enrollmentId =
      notificationKey.substring(0, notificationKey.indexOf('.new.enrollments'));
  var enrollRequest;
  var enrollParamsJson = {};
  enrollParamsJson['enrollmentId'] = enrollmentId;
  final encryptedApkamSymmetricKey =
      jsonDecode(notification.value!)['encryptedApkamSymmetricKey'];
  var encryptionPrivateKey =
      await atClient.getLocalSecondary()!.getEncryptionPrivateKey()!;
  var selfEncryptionKey =
      await atClient.getLocalSecondary()!.getEncryptionSelfKey();
  final apkamSymmetricKey = EncryptionUtil.decryptKey(
      encryptedApkamSymmetricKey, encryptionPrivateKey);
  var encryptedDefaultPrivateEncKey =
      EncryptionUtil.encryptValue(encryptionPrivateKey, apkamSymmetricKey);
  var encryptedDefaultSelfEncKey =
      EncryptionUtil.encryptValue(selfEncryptionKey!, apkamSymmetricKey);
  enrollParamsJson['encryptedDefaultEncryptedPrivateKey'] =
      encryptedDefaultPrivateEncKey;
  enrollParamsJson['encryptedDefaultSelfEncryptionKey'] =
      encryptedDefaultSelfEncKey;
  if (response == 'approve') {
    enrollRequest = 'enroll:approve:${jsonEncode(enrollParamsJson)}\n';
    print('enroll approval request to server: $enrollRequest');
  } else {
    enrollRequest = 'enroll:deny:${jsonEncode(enrollParamsJson)}\n';
    print('enroll denial request $enrollRequest');
  }
  String? enrollResponse = await atClient
      .getRemoteSecondary()!
      .executeCommand(enrollRequest, auth: true);
  print('enroll Response from server: $enrollResponse');
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
    ..rootDomain = 'vip.ve.atsign.zone'
    ..useAtChops = true;

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
    ..rootDomain = 'vip.ve.atsign.zone'
    ..apkamAuthRetryDurationMins = 1
    ..useAtChops = true;
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
