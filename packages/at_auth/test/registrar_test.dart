import 'dart:convert';
import 'package:at_auth/src/registrar/registrar_service_impl.dart';
import 'package:at_auth/src/registrar/registrar_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mock class using mocktail
class MockHttpClient extends Mock implements IOClient {}

void main() {
  late MockHttpClient mockHttpClient;
  late RegistrarServiceImpl registrarService;

  setUp(() {
    mockHttpClient = MockHttpClient();
    registrarService = RegistrarServiceImpl.custom(
      apiKey: 'test-api-key',
      bypassCertificate: true,
      rootDomain: 'example.com',
      weblink: 'https://example.com',
      retryDelayMs: 500,
      httpClient: mockHttpClient,
    );

    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('RegistrarServiceImpl - HTTP Request Tests', () {
    test('getFreeAtSign returns an atSign on success', () async {
      final mockResponse = jsonEncode({
        "success": true,
        "data": {"atsign": "wisefrog"}
      });
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final atSign = await registrarService.getFreeAtSign();

      expect(atSign, 'wisefrog');
    });

    test('getFreeAtSign throws exception on invalid response', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message":
                "Oops, this option is not available at the moment. Please try again later.",
            "status": "error"
          }),
          200,
        ),
      );

      expect(() async => await registrarService.getFreeAtSign(),
          throwsA(isA<RegistrarException>()));
    });

    test('registerPerson succeeds on valid response', () async {
      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'message': 'Sent Successfully'}), 200));

      await registrarService.registerPerson(
          atSign: '@testuser', email: 'test@example.com');
    });

    test('registerPerson throws exception on API failure', () async {
      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(
              jsonEncode({'message': 'Oops, atSign is required.'}), 400));

      expect(
          () async => await registrarService.registerPerson(
              atSign: '@testuser', email: 'test@example.com'),
          throwsA(isA<RegistrarException>()));
    });

    test('authenticateAtSignAndActivate returns cramKey on success', () async {
      final testKey =
          '7ca5f65fga49c7c667251d6f0cb2b0416dbc580b9712d943203ae644ae1b158bcdc02c6bc6453c33b51859773f05c6h5dd9b8a3c017d92cb87cf2ba3371a9d1f';
      final mockResponse =
          jsonEncode({'message': 'Verified', 'cramkey': '@ashish:$testKey'});
      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final cramKey = await registrarService.authenticateAtSignAndActivate(
          atSign: '@testuser', otp: '123456');

      expect(cramKey, testKey);
    });

    test('authenticateAtSignAndActivate throws exception on API failure',
        () async {
      when(() => mockHttpClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'message':
                'Please enter the 4-character verification code that was sent to your email address'
          }),
          400,
        ),
      );

      expect(
          () async => await registrarService.authenticateAtSignAndActivate(
              atSign: '@testuser', otp: '123456'),
          throwsA(isA<RegistrarException>()));
    });

    test('_retryRequest retries failed requests up to maxRetries', () async {
      int attemptCount = 0;

      when(() => mockHttpClient.post(any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'))).thenAnswer((_) async {
        attemptCount++;
        return http.Response('Server error', 500);
      });

      await expectLater(
          () async => await registrarService.registerPerson(
              atSign: '@testuser', email: 'test@example.com'),
          throwsA(isA<RegistrarException>()));

      expect(attemptCount, equals(registrarService.maxRetries));
    });

    test('returns ValidatePersonResponse with cramKey when successful',
        () async {
      final mockResponse =
          jsonEncode({"success": true, "cramKey": "@newatsign:cramKey123"});

      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await registrarService.validatePerson(
        atSign: '@testuser',
        email: 'test@example.com',
        otp: '123456',
      );

      expect(response.cramKey, equals('cramKey123')); // Removes prefix
      expect(response.newAtSign, '@newatsign');
      expect(response.success, isTrue);
    });

    test('returns ValidatePersonResponse with existing atSigns', () async {
      final mockResponse = jsonEncode({
        "data": {
          "atsigns": ["oldAtSign1", "oldAtSign2"],
          "newAtsign": "newAtSign"
        }
      });

      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await registrarService.validatePerson(
        atSign: '@testuser',
        email: 'test@example.com',
        otp: '123456',
      );

      expect(
          response.existingAtSigns, containsAll(["oldAtSign1", "oldAtSign2"]));
      expect(response.newAtSign, equals("newAtSign"));
      expect(response.success, isTrue);
    });

    test('returns ValidatePersonResponse with error message on failure',
        () async {
      final mockResponse =
          jsonEncode({"status": "error", "message": "Invalid OTP", "data": {}});

      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await registrarService.validatePerson(
        atSign: '@testuser',
        email: 'test@example.com',
        otp: 'wrongOTP',
      );

      expect(response.errorMessage, equals("Invalid OTP"));
      expect(response.success, isFalse);
    });

    test(
        'returns ValidatePersonResponse with error message on more than 10 atsigns registered',
        () async {
      final mockResponse = jsonEncode({
        'data': {
          'atsigns': [
            "looo",
            "2467wonderful",
            "birdwatcher",
            "sunset8wild",
            "modernwrestling",
            "bowlinglonely6",
            "apple33",
            "highpeak31",
            "aliveanteater",
            "blueoctopus12"
          ],
        },
        'message':
            'Oops! You already have the maximum number of free atSigns. Please select one of your existing atSigns.',
      });

      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      final response = await registrarService.validatePerson(
        atSign: '@testuser',
        email: 'test@example.com',
        otp: '123456',
      );

      expect(
          response.errorMessage,
          equals(
              "Oops! You already have the maximum number of free atSigns. Please select one of your existing atSigns."));
      expect(response.success, isFalse);
    });

    test('throws RegistrarException for invalid response format', () async {
      final mockResponse = jsonEncode({"unexpected": "data"});

      when(() => mockHttpClient.post(any(),
              headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      expect(
        () async => await registrarService.validatePerson(
          atSign: '@testuser',
          email: 'test@example.com',
          otp: '123456',
        ),
        throwsA(isA<RegistrarException>()),
      );
    });
  });
}
