import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_impl.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:crypton/crypton.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:at_demo_data/at_demo_data.dart';

class MockAtLookUp extends Mock implements AtLookupImpl {}

class MockLookupVerbBuilder extends Fake implements LookupVerbBuilder {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockLookupVerbBuilder());
  });

  test(
      'A test to verify submitting enrollment to server and verify enrollment status is pending',
      () async {
    String atSign = '@alice🛠';
    AtEnrollmentImpl atEnrollmentServiceImpl = AtEnrollmentImpl(atSign);
    AtLookUp mockAtLookUp = MockAtLookUp();

    String? apkamPrivateKey = pkamPrivateKeyMap[atSign]!;
    String? apkamPublicKey = pkamPublicKeyMap[atSign]!;
    String? encryptionPublicKey = encryptionPublicKeyMap[atSign]!;
    String? encryptionPrivateKey = encryptionPrivateKeyMap[atSign]!;
    String? selfEncryptionKey = aesKeyMap[atSign]!;
    String? apkamSymmetricKey = apkamSymmetricKeyMap[atSign]!;

    AtChopsKeys atChopsKeys = AtChopsKeys.create(
        AtEncryptionKeyPair.create(encryptionPublicKey, encryptionPrivateKey),
        AtPkamKeyPair.create(apkamPublicKey, apkamPrivateKey));
    atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);
    atChopsKeys.selfEncryptionKey = AESKey(selfEncryptionKey);
    final iv = AtChopsUtil.generateIVLegacy();

    AtChopsImpl atChopsImpl = AtChopsImpl(atChopsKeys);

    when(() => mockAtLookUp.executeVerb(any(that: LookUpVerbBuilderMatcher())))
        .thenAnswer((_) async => 'data:$encryptionPublicKey');

    when(() => mockAtLookUp.executeCommand(any(that: startsWith('enroll:'))))
        .thenAnswer((_) => Future.value('data:${jsonEncode({
                  'enrollmentId': '123',
                  'status': 'pending'
                })}'));

    when(() =>
        mockAtLookUp.executeCommand(
            any(
                that: startsWith(
                    'keys:get:keyName:123.${AtConstants.defaultEncryptionPrivateKey}')),
            auth: true)).thenAnswer((_) => Future.value(jsonEncode({
          'value': atChopsImpl
              .encryptString(encryptionPrivateKey, EncryptionKeyType.aes256,
                  keyName: 'apkamSymmetricKey', iv: iv)
              .result
        })));

    when(() =>
        mockAtLookUp.executeCommand(
            any(
                that: startsWith(
                    'keys:get:keyName:123.${AtConstants.defaultSelfEncryptionKey}')),
            auth: true)).thenAnswer((_) => Future.value(jsonEncode({
          'value': atChopsImpl
              .encryptString(selfEncryptionKey, EncryptionKeyType.aes256,
                  keyName: 'apkamSymmetricKey', iv: iv)
              .result
        })));
    when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: '123'))
        .thenAnswer((_) => Future.value(true));

    when(() => (mockAtLookUp as AtLookupImpl).close())
        .thenAnswer((_) async => ());

    EnrollmentRequest enrollmentRequest = EnrollmentRequest(
        appName: 'wavi',
        deviceName: 'pixel',
        otp: 'A123FE',
        namespaces: {'wavi': 'rw'});

    AtEnrollmentResponse atEnrollmentResponse =
        await atEnrollmentServiceImpl.submit(enrollmentRequest, mockAtLookUp);
    expect(atEnrollmentResponse.enrollmentId, '123');
    expect(atEnrollmentResponse.enrollStatus, EnrollmentStatus.pending);
  });

  group('A group of tests related EnrollmentRequestDecision', () {
    test('A test to verify the approve enrollment', () async {
      String atSign = '@alice🛠';

      String? apkamPrivateKey = pkamPrivateKeyMap[atSign]!;
      String? apkamPublicKey = pkamPublicKeyMap[atSign]!;
      String? encryptionPublicKey = encryptionPublicKeyMap[atSign]!;
      String? encryptionPrivateKey = encryptionPrivateKeyMap[atSign]!;
      String? selfEncryptionKey = aesKeyMap[atSign]!;
      String? apkamSymmetricKey = apkamSymmetricKeyMap[atSign]!;

      String encryptedAPKAMSymmetricKey =
          RSAPublicKey.fromString(encryptionPublicKey)
              .encrypt(apkamSymmetricKey);

      AtChopsKeys atChopsKeys = AtChopsKeys.create(
          AtEncryptionKeyPair.create(encryptionPublicKey, encryptionPrivateKey),
          AtPkamKeyPair.create(apkamPublicKey, apkamPrivateKey));
      atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);
      atChopsKeys.selfEncryptionKey = AESKey(selfEncryptionKey);

      AtChopsImpl atChopsImpl = AtChopsImpl(atChopsKeys);

      AtLookUp mockAtLookUp = MockAtLookUp();

      AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl(atSign);

      when(() => mockAtLookUp.atChops).thenReturn(atChopsImpl);

      when(() =>
          mockAtLookUp.executeCommand(any(that: startsWith('enroll:approve')),
              auth: true)).thenAnswer((_) => Future.value('data:${jsonEncode({
                'status': 'approved',
                'enrollmentId': '4be2d358-074d-4e3b-99f3-64c4da01532f'
              })}'));

      EnrollmentRequestDecision enrollmentRequestDecision =
          EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
              enrollmentId: '4be2d358-074d-4e3b-99f3-64c4da01532f',
              encryptedAPKAMSymmetricKey: encryptedAPKAMSymmetricKey));

      AtEnrollmentResponse atEnrollmentResponse = await atEnrollmentBase
          .approve(enrollmentRequestDecision, mockAtLookUp);

      expect(atEnrollmentResponse.enrollmentId,
          '4be2d358-074d-4e3b-99f3-64c4da01532f');
      expect(atEnrollmentResponse.enrollStatus, EnrollmentStatus.approved);
    });

    test('A test to verify the deny enrollment', () async {
      String atSign = '@alice🛠';

      String? apkamPrivateKey = pkamPrivateKeyMap[atSign]!;
      String? apkamPublicKey = pkamPublicKeyMap[atSign]!;
      String? encryptionPublicKey = encryptionPublicKeyMap[atSign]!;
      String? encryptionPrivateKey = encryptionPrivateKeyMap[atSign]!;
      String? selfEncryptionKey = aesKeyMap[atSign]!;
      String? apkamSymmetricKey = apkamSymmetricKeyMap[atSign]!;

      AtChopsKeys atChopsKeys = AtChopsKeys.create(
          AtEncryptionKeyPair.create(encryptionPublicKey, encryptionPrivateKey),
          AtPkamKeyPair.create(apkamPublicKey, apkamPrivateKey));
      atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);
      atChopsKeys.selfEncryptionKey = AESKey(selfEncryptionKey);

      AtChopsImpl atChopsImpl = AtChopsImpl(atChopsKeys);

      AtLookUp mockAtLookUp = MockAtLookUp();

      AtEnrollmentBase atEnrollmentBase = AtEnrollmentImpl(atSign);

      when(() => mockAtLookUp.atChops).thenReturn(atChopsImpl);

      when(() => mockAtLookUp
              .executeCommand(any(that: startsWith('enroll:deny')), auth: true))
          .thenAnswer((_) => Future.value('data:${jsonEncode({
                    'status': 'denied',
                    'enrollmentId': '4be2d358-074d-4e3b-99f3-64c4da01532f'
                  })}'));

      EnrollmentRequestDecision enrollmentRequestDecision =
          EnrollmentRequestDecision.denied(
              '4be2d358-074d-4e3b-99f3-64c4da01532f');

      AtEnrollmentResponse atEnrollmentResponse =
          await atEnrollmentBase.deny(enrollmentRequestDecision, mockAtLookUp);

      expect(atEnrollmentResponse.enrollmentId,
          '4be2d358-074d-4e3b-99f3-64c4da01532f');
      expect(atEnrollmentResponse.enrollStatus, EnrollmentStatus.denied);
    });
  });

  group('A group of test related to AtEnrollmentBuilder', () {
    test(
        'A test to verify generation of initial onboarding enrollment request - default operation request',
        () {
      AtInitialEnrollmentRequestBuilder atInitialEnrollmentRequestBuilder =
          AtInitialEnrollmentRequestBuilder()
            ..setAppName('wavi')
            ..setDeviceName('pixel')
            ..setNamespaces({'wavi': 'rw'})
            ..setEncryptedDefaultEncryptionPrivateKey('testPrivateKey')
            ..setEncryptedDefaultSelfEncryptionKey('testSelfKey')
            ..setApkamPublicKey('testApkamPublicKey');
      // ignore: deprecated_member_use_from_same_package
      AtInitialEnrollmentRequest atInitialEnrollmentRequest =
          atInitialEnrollmentRequestBuilder.build();

      expect(atInitialEnrollmentRequest.appName, 'wavi');
      expect(atInitialEnrollmentRequest.deviceName, 'pixel');
      expect(atInitialEnrollmentRequest.namespaces, {'wavi': 'rw'});
      expect(atInitialEnrollmentRequest.encryptedDefaultEncryptionPrivateKey,
          'testPrivateKey');
      expect(atInitialEnrollmentRequest.encryptedDefaultSelfEncryptionKey,
          'testSelfKey');
      expect(atInitialEnrollmentRequest.apkamPublicKey, 'testApkamPublicKey');
      expect(atInitialEnrollmentRequest.enrollOperationEnum,
          EnrollOperationEnum.request);
    });
    test(
        'A test to verify generation of initial onboarding enrollment request - set operation',
        () {
      AtInitialEnrollmentRequestBuilder atInitialEnrollmentRequestBuilder =
          AtInitialEnrollmentRequestBuilder()
            ..setAppName('wavi')
            ..setDeviceName('pixel')
            ..setNamespaces({'wavi': 'rw'})
            ..setEncryptedDefaultEncryptionPrivateKey('testPrivateKey')
            ..setEncryptedDefaultSelfEncryptionKey('testSelfKey')
            ..setApkamPublicKey('testApkamPublicKey')
            ..setEnrollOperationEnum(EnrollOperationEnum.approve);
      // ignore: deprecated_member_use_from_same_package
      AtInitialEnrollmentRequest atInitialEnrollmentRequest =
          atInitialEnrollmentRequestBuilder.build();

      expect(atInitialEnrollmentRequest.appName, 'wavi');
      expect(atInitialEnrollmentRequest.deviceName, 'pixel');
      expect(atInitialEnrollmentRequest.namespaces, {'wavi': 'rw'});
      expect(atInitialEnrollmentRequest.encryptedDefaultEncryptionPrivateKey,
          'testPrivateKey');
      expect(atInitialEnrollmentRequest.encryptedDefaultSelfEncryptionKey,
          'testSelfKey');
      expect(atInitialEnrollmentRequest.apkamPublicKey, 'testApkamPublicKey');
      expect(atInitialEnrollmentRequest.enrollOperationEnum,
          EnrollOperationEnum.approve);
    });

    test(
        'A test to verify generation of new enrollment request - default operation request',
        () {
      AtNewEnrollmentRequestBuilder atNewEnrollmentRequestBuilder =
          AtNewEnrollmentRequestBuilder()
            ..setAppName('wavi')
            ..setDeviceName('pixel')
            ..setNamespaces({'wavi': 'rw'})
            ..setOtp('A123FE')
            ..setApkamPublicKey('testApkamPublicKey');
      // ignore: deprecated_member_use_from_same_package
      AtNewEnrollmentRequest atNewEnrollmentRequest =
          atNewEnrollmentRequestBuilder.build();

      expect(atNewEnrollmentRequest.appName, 'wavi');
      expect(atNewEnrollmentRequest.deviceName, 'pixel');
      expect(atNewEnrollmentRequest.namespaces, {'wavi': 'rw'});
      expect(atNewEnrollmentRequest.apkamPublicKey, 'testApkamPublicKey');
      expect(atNewEnrollmentRequest.otp, 'A123FE');
      expect(atNewEnrollmentRequest.enrollOperationEnum,
          EnrollOperationEnum.request);
    });

    test(
        'A test to verify generation of new enrollment request - set operation',
        () {
      AtNewEnrollmentRequestBuilder atNewEnrollmentRequestBuilder =
          AtNewEnrollmentRequestBuilder()
            ..setAppName('wavi')
            ..setDeviceName('pixel')
            ..setNamespaces({'wavi': 'rw'})
            ..setOtp('A123FE')
            ..setApkamPublicKey('testApkamPublicKey')
            ..setEnrollOperationEnum(EnrollOperationEnum.request);
      // ignore: deprecated_member_use_from_same_package
      AtNewEnrollmentRequest atNewEnrollmentRequest =
          atNewEnrollmentRequestBuilder.build();

      expect(atNewEnrollmentRequest.appName, 'wavi');
      expect(atNewEnrollmentRequest.deviceName, 'pixel');
      expect(atNewEnrollmentRequest.namespaces, {'wavi': 'rw'});
      expect(atNewEnrollmentRequest.apkamPublicKey, 'testApkamPublicKey');
      expect(atNewEnrollmentRequest.otp, 'A123FE');
      expect(atNewEnrollmentRequest.enrollOperationEnum,
          EnrollOperationEnum.request);
    });

    test('A test to verify generation of enrollment approval request', () {
      AtEnrollmentNotificationRequestBuilder atEnrollmentNotificationBuilder =
          AtEnrollmentNotificationRequestBuilder()
            ..setEnrollmentId('ABC-123-ID')
            ..setEncryptedApkamSymmetricKey('dummy-apkam-symmetric-key')
            ..setEnrollOperationEnum(EnrollOperationEnum.approve);
      // ignore: deprecated_member_use_from_same_package
      AtEnrollmentNotificationRequest atEnrollmentNotificationRequest =
          atEnrollmentNotificationBuilder.build();

      expect(atEnrollmentNotificationRequest.enrollmentId, 'ABC-123-ID');
      expect(atEnrollmentNotificationRequest.encryptedApkamSymmetricKey,
          'dummy-apkam-symmetric-key');
      expect(atEnrollmentNotificationRequest.enrollOperationEnum,
          EnrollOperationEnum.approve);
    });

    test('A test to verify generation of enrollment deny request', () {
      AtEnrollmentRequestBuilder atEnrollmentRequestBuilder =
          // ignore: deprecated_member_use_from_same_package
          AtEnrollmentRequest.deny()..setEnrollmentId('ABC-123-ID');
      // ignore: deprecated_member_use_from_same_package
      AtEnrollmentRequest atEnrollmentRequest =
          atEnrollmentRequestBuilder.build();

      expect(atEnrollmentRequest.enrollmentId, 'ABC-123-ID');
    });
  });
  group('Group of tests to check createEnrollVerbBuilder method', () {
    test(
        'A test to verify  createEnrollVerbBuilder for AtInitialEnrollmentRequest',
        () {
      var enrollmentImpl = AtEnrollmentImpl('@alice');
      // ignore: deprecated_member_use_from_same_package
      AtInitialEnrollmentRequest request = (AtInitialEnrollmentRequestBuilder()
            ..setAppName('TestApp')
            ..setDeviceName('TestDevice')
            ..setNamespaces({"wavi": "rw"})
            ..setEncryptedDefaultEncryptionPrivateKey('encryptedPrivateKey')
            ..setEncryptedDefaultSelfEncryptionKey('encryptedSelfEncryptionKey')
            ..setApkamPublicKey('apkamPublicKey'))
          .build();

      // ignore: deprecated_member_use_from_same_package
      var result = enrollmentImpl.createEnrollVerbBuilder(request);

      expect(result.appName, equals('TestApp'));
      expect(result.deviceName, equals('TestDevice'));
      expect(result.namespaces, equals({'wavi': 'rw'}));
      expect(result.encryptedDefaultEncryptionPrivateKey,
          equals('encryptedPrivateKey'));
      expect(result.encryptedDefaultSelfEncryptionKey,
          equals('encryptedSelfEncryptionKey'));
      expect(result.apkamPublicKey, equals('apkamPublicKey'));
      expect(result.otp, isNull);
      expect(result.encryptedAPKAMSymmetricKey, isNull);
    });

    test('A test for  createEnrollVerbBuilder for AtNewEnrollmentRequest', () {
      var request = (AtNewEnrollmentRequestBuilder()
            ..setAppName('TestApp')
            ..setDeviceName('TestDevice')
            ..setNamespaces({"wavi": "rw", "contact": "r"})
            ..setOtp('A1CFG3')
            ..setApkamPublicKey('apkamPublicKey'))
          .build();

      var enrollmentImpl = AtEnrollmentImpl('@alice');
      AtPkamKeyPair atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
      // ignore: deprecated_member_use_from_same_package
      var result = enrollmentImpl.createEnrollVerbBuilder(request,
          atPkamKeyPair: atPkamKeyPair);

      // Assert
      expect(result.appName, equals('TestApp'));
      expect(result.deviceName, equals('TestDevice'));
      expect(result.namespaces, equals({"wavi": "rw", "contact": "r"}));
      expect(result.otp, equals('A1CFG3'));
      expect(result.apkamPublicKey, isNotNull);
      expect(result.encryptedDefaultEncryptionPrivateKey, isNull);
      expect(result.encryptedDefaultSelfEncryptionKey, isNull);
    });
  });
}

class LookUpVerbBuilderMatcher extends Matcher {
  @override
  Description describe(Description description) {
    return description;
  }

  @override
  bool matches(item, Map matchState) {
    if (item is LookupVerbBuilder) {
      return true;
    }
    return false;
  }
}
