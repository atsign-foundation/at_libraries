import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
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
      'A test to verify submitting enrollment to server and generate atKeys for enrolled device',
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

    AtEnrollmentRequest atEnrollmentRequest = (AtEnrollmentRequest.request()
          ..setAppName('wavi')
          ..setDeviceName('pixel')
          ..setOtp('12345')
          ..setNamespaces({'wavi': 'rw'}))
        .build();

    AtPkamKeyPair atPkamKeyPair =
        AtPkamKeyPair.create(apkamPublicKey, apkamPrivateKey);
    SymmetricKey symmetricKey = AESKey(apkamSymmetricKey);

    AtEnrollmentResponse enrollmentSubmissionResponse =
        await atEnrollmentServiceImpl.enrollInternal(
            atEnrollmentRequest, mockAtLookUp, atPkamKeyPair, symmetricKey);
    expect(enrollmentSubmissionResponse.enrollmentId, '123');
    expect(enrollmentSubmissionResponse.enrollStatus, EnrollStatus.pending);
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
