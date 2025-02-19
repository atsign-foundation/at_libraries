import 'dart:convert';
import 'dart:io';

import 'package:at_auth/src/registrar/registrar_service_base.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'registar_validate_person_response.dart';
import 'registrar_exception.dart';

class RegistrarServiceImpl implements RegistrarServiceBase {
  RegistrarServiceImpl.dev({
    required this.apiKey,
    int version = 3,
    bool bypassCertificate = true,
    this.maxRetries = 3,
    this.retryDelayMs = 2000,
  })  : _httpClient = IOClient(_createHttpClient(bypassCertificate: bypassCertificate)),
        _apiPath = '/api/app/v$version',
        rootDomain = 'my.atsign.wtf',
        weblink = 'https://atsign.wtf',
        assert(version >= 1 && version <= 3, 'Version must be between 1 and 3'),
        assert(maxRetries > 0, 'Max retries must be greater than 0'),
        assert(retryDelayMs > 0, 'Retry delay must be greater than 0');

  RegistrarServiceImpl.prod({
    required this.apiKey,
    int version = 3,
    this.maxRetries = 3,
    this.retryDelayMs = 2000,
  })  : _httpClient = IOClient(_createHttpClient(bypassCertificate: false)),
        _apiPath = '/api/app/v$version',
        rootDomain = 'my.atsign.com',
        weblink = 'https://atsign.com',
        assert(version >= 1 && version <= 3, 'Version must be between 1 and 3'),
        assert(maxRetries > 0, 'Max retries must be greater than 0'),
        assert(retryDelayMs > 0, 'Retry delay must be greater than 0');

  RegistrarServiceImpl.custom({
    required this.apiKey,
    required this.rootDomain,
    required this.weblink,
    required bool bypassCertificate,
    int version = 3,
    this.maxRetries = 3,
    this.retryDelayMs = 2000,
    IOClient? httpClient,
  })  : _httpClient = httpClient ?? IOClient(_createHttpClient(bypassCertificate: bypassCertificate)),
        _apiPath = '/api/app/v$version',
        assert(version >= 1 && version <= 3, 'Version must be between 1 and 3'),
        assert(maxRetries > 0, 'Max retries must be greater than 0'),
        assert(retryDelayMs > 0, 'Retry delay must be greater than 0');

  final IOClient _httpClient;
  final String rootDomain;
  final String _apiPath;
  final int maxRetries;
  final int retryDelayMs;
  final String apiKey;
  final String weblink;

  /// Creates an `HttpClient` with a certificate bypass in non-production environments.
  static HttpClient _createHttpClient({required bool bypassCertificate}) {
    final client = HttpClient();
    if (bypassCertificate) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }

  /// Sends a POST request to the registrar API with retry logic.
  Future<http.Response> _postRequest(String path, Map<String, String?>? data) async {
    final url = Uri.https(rootDomain, '$_apiPath/$path');
    final body = data != null ? json.encode(data) : null;

    return _retryRequest(() async {
      final response = await _httpClient.post(
        url,
        body: body,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw RegistrarException(
        error: 'Request failed: ${response.statusCode} - ${response.body}',
        message: 'Request failed with status code ${response.statusCode}',
      );
    });
  }

  /// Sends a GET request to the registrar API with retry logic.
  Future<http.Response> _getRequest(String path) async {
    final url = Uri.https(rootDomain, '$_apiPath/$path');

    return _retryRequest(() async {
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw RegistrarException(
        error: '${response.statusCode} - ${response.body}',
        message: 'Request failed with status code ${response.statusCode}',
      );
    });
  }

  /// Retries a function `_maxRetries` times with a delay.
  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await request();
      } catch (e) {
        // Would be cleaner to move this logic outside the for loop but
        // keeping this logic so that the error can be reported in exception.
        if (attempt == maxRetries - 1) {
          final message = e is RegistrarException ? e.message : e.toString();
          throw RegistrarException(
            error: 'Request failed after $maxRetries attempts: $message',
            message: message,
          );
        }
        await Future.delayed(Duration(milliseconds: retryDelayMs));
      }
    }
    throw Exception('Unexpected error in _retryRequest');
  }

  @override
  Future<String> getFreeAtSign() async {
    final response = await _getRequest('get-free-atsign/');

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      final data = body['data'] as Map<String, dynamic>;
      if (data['atsign'] is String) {
        return data['atsign'] as String;
      }
    }
    throw RegistrarException(
      error: 'Invalid response format: $body',
      message: 'Invalid response format',
    );
  }

  @override
  Future<void> registerPerson({required String atSign, required String email}) async {
    final response = await _postRequest('register-person/', {
      'atsign': atSign,
      'email': email,
    });

    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic> && body['message'] is String) {
      if (body['message'] == 'Sent Successfully') {
        return;
      } else {
        throw RegistrarException(
          error: body['message'],
          message: body['message'],
        );
      }
    }
    throw RegistrarException(
      error: 'Invalid response format: $body',
      message: 'Invalid response format',
    );
  }

  @override
  Future<ValidatePersonResponse> validatePerson({
    required String atSign,
    required String email,
    required String otp,
  }) async {
    final response = await _postRequest('validate-person/', {
      'atsign': atSign,
      'email': email,
      'otp': otp,
    });

    final body = jsonDecode(response.body);

    if (body is Map<String, dynamic>) {
      return ValidatePersonResponse.fromJson(body);
    }

    throw RegistrarException(
      error: 'Invalid response format: $body',
      message: 'Invalid response format',
    );
  }

  @override
  Future<void> authenticateAtSign({required String atSign}) async {
    final response = await _postRequest('authenticate/atsign', {
      'atsign': atSign,
    });

    final body = jsonDecode(response.body);

    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message == 'Sent Successfully') {
        return;
      } else {
        throw RegistrarException(
          error: 'authenticate/atsign failed: $message',
          message: message,
        );
      }
    }

    throw RegistrarException(
      error: 'Invalid response format: $body',
      message: 'Invalid response format',
    );
  }

  @override
  Future<String> authenticateAtSignAndActivate({required String atSign, required String otp}) async {
    final response = await _postRequest('authenticate/atsign/activate', {
      'atsign': atSign,
      'otp': otp,
    });

    final body = jsonDecode(response.body);

    if (body is Map<String, dynamic>) {
      final cramKey = (body['cramkey'] as String?)?.split(':')[1];
      if (cramKey != null) {
        return cramKey;
      } else {
        final message = body['message'] as String;
        throw RegistrarException(
          error: 'authenticate/atsign/activate failed: $message',
          message: message,
        );
      }
    }

    throw RegistrarException(
      error: 'Invalid response format: $body',
      message: 'Invalid response format',
    );
  }

  @override
  String get registrarUrlSite => weblink;
}
