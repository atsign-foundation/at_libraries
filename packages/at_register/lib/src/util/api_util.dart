import 'dart:convert';
import 'dart:io';

import 'package:at_utils/at_logger.dart';
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
    http.Response response = await _ioClient!.post(
      uri,
      body: body,
      headers: <String, String>{
        'Authorization': RegistrarConstants.authorization,
        'Content-Type': RegistrarConstants.contentType,
      },
    );
    if (RegistrarConstants.isDebugMode) {
      AtSignLogger('AtRegister').shout('Sent request to url: $uri | Request Body: $body');
      AtSignLogger('AtRegister').shout('Got Response: ${response.body}');
    }
    return response;
  }

  static bool enforceEmailRegex(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  static bool enforceOtpRegex(String otp) {
    if (otp.length == 4) {
      return RegExp(r"^[a-zA-z0-9]").hasMatch(otp);
    }
    return false;
  }
  
  static String formatExceptionMessage(String exception){
    return exception.replaceAll('Exception:', '');
  }

  /// Method to get verification code from user input
  /// validates code locally and retries taking user input if invalid
  /// Returns only when the user has provided a 4-length String only containing numbers and alphabets
  static String getVerificationCodeFromUser() {
    String? otp;
    stdout.writeln(
        '[Action Required] Enter your verification code: (verification code is not case-sensitive)');
    otp = stdin.readLineSync()!.toUpperCase();
    while (!enforceOtpRegex(otp!)) {
      stderr.writeln(
          '[Unable to proceed] The verification code you entered is invalid.\n'
          'Please check your email for a 4-character verification code.\n'
          'If you cannot see the code in your inbox, please check your spam/junk/promotions folders.\n'
          '[Action Required] Enter your verification code:');
      otp = stdin.readLineSync()!.toUpperCase();
    }
    return otp;
  }

  static String readUserAtsignChoice(List<String>? atsigns) {
    if (atsigns == null) {
      throw AtRegisterException('Fetched atsigns list is null');
    } else if (atsigns.length == 1) {
      return atsigns[0];
    }
    stdout.writeln(
        'Please select one atsign from the list above. Input the number of the atsign you wish to select.');
    stdout.writeln(
        'For example, type \'2\'+\'Enter\' to select the second atsign (or) just hit \'Enter\' to select the first one');
    stdout.writeln('Valid range is 1 - ${atsigns.length + 1}');
    int? choice = int.tryParse(stdin.readLineSync()!);
    if (choice == null) {
      return atsigns[0];
    } else {
      return atsigns[choice];
    }
  }
}
