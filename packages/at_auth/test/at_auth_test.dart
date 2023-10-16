import 'package:at_auth/src/auth/pkam_authenticator.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:at_auth/at_auth.dart';
import 'package:at_utils/at_logger.dart';

// Create a mock for AtLookUp
class MockAtLookUp extends Mock implements AtLookupImpl {}

// Create a mock for AtChops
class MockAtChops extends Mock implements AtChops {}

class MockPkamAuthenticator extends Mock implements PkamAuthenticator {}

class FakeUpdateVerbBuilder extends Fake implements UpdateVerbBuilder {}

class FakeDeleteVerbBuilder extends Fake implements DeleteVerbBuilder {}

class FakeVerbBuilder extends Fake implements VerbBuilder {}

void main() {
  late AtAuthImpl atAuth;
  late MockAtLookUp mockAtLookUp;
  late MockPkamAuthenticator mockPkamAuthenticator;
  final String testEnrollmentId = '352b78c8-4b6f-4d07-a9cf-5466512ffa44';

  setUp(() {
    mockAtLookUp = MockAtLookUp();
    mockPkamAuthenticator = MockPkamAuthenticator();
    atAuth = AtAuthImpl(
        atLookUp: mockAtLookUp, pkamAuthenticator: mockPkamAuthenticator);
    registerFallbackValue(FakeVerbBuilder());
  });
  group('AtAuthImpl authentication tests', () {
    test('Test authenticate() true with keys file', () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenAnswer((_) => Future.value(true));
      when(() =>
          mockPkamAuthenticator.authenticate(
              enrollmentId: testEnrollmentId)).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;
      atAuthRequest.atKeysFilePath = 'test/data/@alice🛠_key.atKeys';

      final response = await atAuth.authenticate(atAuthRequest);

      expect(response.isSuccessful, true);
      expect(response.enrollmentId, testEnrollmentId);
    });

    test('Test authenticate() false with keys file', () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenAnswer((_) => Future.value(false));
      when(() => mockPkamAuthenticator.authenticate(
              enrollmentId: testEnrollmentId))
          .thenAnswer((_) =>
              Future.value(AtAuthResponse('@alice🛠')..isSuccessful = false));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;
      atAuthRequest.atKeysFilePath = 'test/data/@alice🛠_key.atKeys';

      final response = await atAuth.authenticate(atAuthRequest);

      expect(response.isSuccessful, false);
      expect(response.enrollmentId, testEnrollmentId);
    });

    test('Test authenticate() with atAuthKeys set', () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenAnswer((_) => Future.value(true));
      when(() =>
          mockPkamAuthenticator.authenticate(
              enrollmentId: testEnrollmentId)).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;
      atAuthRequest.atAuthKeys = AtAuthKeys()
        ..apkamPublicKey = 'testApkamPublicKey'
        ..apkamPrivateKey = 'testApkamPrivateKey'
        ..defaultEncryptionPublicKey = 'defaultEncryptionPublicKey'
        ..defaultEncryptionPrivateKey = 'defaultEncryptionPrivateKey'
        ..defaultSelfEncryptionKey = 'defaultSelfEncryptionKey'
        ..enrollmentId = testEnrollmentId;

      final response = await atAuth.authenticate(atAuthRequest);

      expect(response.isSuccessful, true);
      expect(response.enrollmentId, testEnrollmentId);
    });

    test(
        'Test authenticate() - throw exception is pkamPrivateKey is not set for default auth mode.',
        () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenAnswer((_) => Future.value(true));
      when(() =>
          mockPkamAuthenticator.authenticate(
              enrollmentId: testEnrollmentId)).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;
      atAuthRequest.atAuthKeys = AtAuthKeys()
        ..apkamPublicKey = 'testApkamPublicKey'
        ..defaultEncryptionPublicKey = 'defaultEncryptionPublicKey'
        ..defaultEncryptionPrivateKey = 'defaultEncryptionPrivateKey'
        ..defaultSelfEncryptionKey = 'defaultSelfEncryptionKey'
        ..enrollmentId = testEnrollmentId;

      expect(() async => await atAuth.authenticate(atAuthRequest),
          throwsA(isA<AtPrivateKeyNotFoundException>()));
    });

    test(
        'Test authenticate throws exception when keysfile path and atAuthKeys is not set in request',
        () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenAnswer((_) => Future.value(true));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;

      expect(() async => await atAuth.authenticate(atAuthRequest),
          throwsA(isA<AtAuthenticationException>()));
    });

    test(
        'Test authenticate() pkamAuthenticate method throws UnAuthenticatedException',
        () async {
      when(() => mockAtLookUp.pkamAuthenticate(enrollmentId: testEnrollmentId))
          .thenThrow(UnAuthenticatedException('Unauthenticated'));
      when(() => mockPkamAuthenticator.authenticate(
              enrollmentId: testEnrollmentId))
          .thenThrow(AtAuthenticationException('Unauthenticated'));
      final atAuthRequest = AtAuthRequest('@alice🛠', 'example.com', 64);
      atAuthRequest.enrollmentId = testEnrollmentId;
      atAuthRequest.atKeysFilePath = 'test/data/@alice🛠_key.atKeys';

      expect(() async => await atAuth.authenticate(atAuthRequest),
          throwsA(isA<AtAuthenticationException>()));
    });
  });
  group('AtAuthImpl onboarding tests', () {
    var testCramSecret = 'cram123';
    test('Test onboard - authenticate_cram returns true', () async {
      when(() => mockAtLookUp.authenticate_cram(testCramSecret))
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtLookUp.executeCommand(any()))
          .thenAnswer((_) => Future.value('data:1'));
      when(() => mockAtLookUp.executeVerb(any()))
          .thenAnswer((_) => Future.value('data:2'));

      when(() => mockAtLookUp.close()).thenAnswer((_) async => {});
      when(() => mockPkamAuthenticator.authenticate()).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));

      final atOnboardingRequest = AtOnboardingRequest('@alice🛠')
        ..rootDomain = 'test.atsign.com'
        ..rootPort = 64;

      final response =
          await atAuth.onboard(atOnboardingRequest, testCramSecret);

      expect(response.isSuccessful, true);
    });
    test('Test onboard - authenticate_cram returns false', () async {
      when(() => mockAtLookUp.authenticate_cram(testCramSecret))
          .thenAnswer((_) => Future.value(false));
      when(() => mockAtLookUp.executeCommand(any()))
          .thenAnswer((_) => Future.value('data:1'));
      when(() => mockAtLookUp.executeVerb(any()))
          .thenAnswer((_) => Future.value('data:2'));

      when(() => mockAtLookUp.close()).thenAnswer((_) async => {});
      when(() => mockPkamAuthenticator.authenticate()).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));

      final atOnboardingRequest = AtOnboardingRequest('@alice🛠')
        ..rootDomain = 'test.atsign.com'
        ..rootPort = 64;

      expect(
          () async => await atAuth.onboard(atOnboardingRequest, testCramSecret),
          throwsA(isA<AtAuthenticationException>()));
    });

    test('Test onboard - enable enrollment', () async {
      when(() => mockAtLookUp.authenticate_cram(testCramSecret))
          .thenAnswer((_) => Future.value(true));
      var mockEnrollResponse =
          'data:{"enrollmentId":"abc123","status":"approved"}';
      when(() => mockAtLookUp.executeCommand(any(that: startsWith('enroll:'))))
          .thenAnswer((_) => Future.value(mockEnrollResponse));
      when(() => mockAtLookUp.executeVerb(any()))
          .thenAnswer((_) => Future.value('data:2'));

      when(() => mockAtLookUp.close()).thenAnswer((_) async => {});
      when(() => mockPkamAuthenticator.authenticate(enrollmentId: "abc123"))
          .thenAnswer((_) =>
              Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));

      final atOnboardingRequest = AtOnboardingRequest('@alice🛠')
        ..rootDomain = 'test.atsign.com'
        ..rootPort = 64
        ..enableEnrollment = true
        ..appName = 'wavi'
        ..authMode = PkamAuthMode.keysFile
        ..deviceName = 'iphone';

      final response =
          await atAuth.onboard(atOnboardingRequest, testCramSecret);

      expect(response.isSuccessful, true);
      expect(response.enrollmentId, 'abc123');
    });

    test('Test onboard - enable enrollment set to false', () async {
      when(() => mockAtLookUp.authenticate_cram(testCramSecret))
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtLookUp.executeCommand(any()))
          .thenAnswer((_) => Future.value('data:1'));
      when(() => mockAtLookUp.executeVerb(any()))
          .thenAnswer((_) => Future.value('data:2'));

      when(() => mockAtLookUp.close()).thenAnswer((_) async => {});
      when(() => mockPkamAuthenticator.authenticate()).thenAnswer(
          (_) => Future.value(AtAuthResponse('@alice🛠')..isSuccessful = true));

      final atOnboardingRequest = AtOnboardingRequest('@alice🛠')
        ..rootDomain = 'test.atsign.com'
        ..rootPort = 64
        ..enableEnrollment = false
        ..appName = 'wavi'
        ..deviceName = 'iphone';

      final response =
          await atAuth.onboard(atOnboardingRequest, testCramSecret);
      expect(response.isSuccessful, true);
    });

    test('Test onboard - pkam authenticate is false', () async {
      when(() => mockAtLookUp.authenticate_cram(testCramSecret))
          .thenAnswer((_) => Future.value(true));
      when(() => mockAtLookUp.executeCommand(any()))
          .thenAnswer((_) => Future.value('data:1'));
      when(() => mockAtLookUp.executeVerb(any()))
          .thenAnswer((_) => Future.value('data:2'));

      when(() => mockAtLookUp.close()).thenAnswer((_) async => {});
      when(() => mockPkamAuthenticator.authenticate()).thenAnswer((_) =>
          Future.value(AtAuthResponse('@alice🛠')..isSuccessful = false));

      final atOnboardingRequest = AtOnboardingRequest('@alice🛠')
        ..rootDomain = 'test.atsign.com'
        ..rootPort = 64
        ..enableEnrollment = false
        ..appName = 'wavi'
        ..deviceName = 'iphone';

      expect(
          () async => await atAuth.onboard(atOnboardingRequest, testCramSecret),
          throwsA(isA<AtAuthenticationException>()));
    });
  });
}
