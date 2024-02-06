import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../at_register.dart';

class ApiUtil {
  static IOClient? _ioClient;

  static void _createClient() {
    HttpClient ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    _ioClient = IOClient(ioc);
  }

  /// generic GET request
  static Future<http.Response> getRequest(String authority, String path) async {
    if (_ioClient == null) _createClient();
    Uri uri = Uri.https(authority, path);
    http.Response response =
        (await _ioClient!.get(uri, headers: <String, String>{
      'Authorization': RegistrarConstants.authorization,
      'Content-Type': RegistrarConstants.contentType,
    }));
    return response;
  }

  /// generic POST request
  static Future<http.Response> postRequest(
      String authority, String path, Map<String, String?> data) async {
    if (_ioClient == null) _createClient();

    Uri uri = Uri.https(authority, path);

    String body = json.encode(data);
    if (RegistrarConstants.isDebugMode) {
      stdout.writeln('Sending request to url: $uri\nRequest Body: $body');
    }
    http.Response response = await _ioClient!.post(
      uri,
      body: body,
      headers: <String, String>{
        'Authorization': RegistrarConstants.authorization,
        'Content-Type': RegistrarConstants.contentType,
      },
    );
    if (RegistrarConstants.isDebugMode) {
      print('Got Response: ${response.body}');
    }
    return response;
  }

  static bool validateEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  static bool validateVerificationCode(String otp) {
    if (otp.length == 4) {
      return RegExp(r"^[a-zA-z0-9]").hasMatch(otp);
    }
    return false;
  }

  /// Method to get verification code from user input
  /// validates code locally and retries taking user input if invalid
  /// Returns only when the user has provided a 4-length String only containing numbers and alphabets
  static String getVerificationCodeFromUser() {
    String? otp;
    stdout.writeln(
        '[Action Required] Enter your verification code: (verification code is not case-sensitive)');
    otp = stdin.readLineSync()!.toUpperCase();
    while (!validateVerificationCode(otp!)) {
      stderr.writeln(
          '[Unable to proceed] The verification code you entered is invalid.\n'
          'Please check your email for a 4-character verification code.\n'
          'If you cannot see the code in your inbox, please check your spam/junk/promotions folders.\n'
          '[Action Required] Enter your verification code:');
      otp = stdin.readLineSync()!.toUpperCase();
    }
    return otp;
  }
}
