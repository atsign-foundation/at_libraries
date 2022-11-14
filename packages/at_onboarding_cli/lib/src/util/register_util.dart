import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_client/at_client.dart' as at_client;
import 'package:at_onboarding_cli/src/util/register_api_constants.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

///class containing utilities to perform registration of a free atsign
class RegisterUtil {
  IOClient? _ioClient;

  void _createClient() {
    HttpClient ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    _ioClient = IOClient(ioc);
  }

  /// Returns a Future<List<String>> containing free available atSigns of count provided as input.
  Future<List<String>> getFreeAtSigns(
      {int amount = 1,
      String authority = RegisterApiConstants.apiHostProd}) async {
    List<String> atSigns = <String>[];
    Response response;
    for (int i = 0; i < amount; i++) {
      // get request at my.atsign.com/api/app/v3/get-free-atsign/
      response =
          await _getRequest(authority, RegisterApiConstants.pathGetFreeAtSign);
      if (response.statusCode == 200) {
        String atSign = jsonDecode(response.body)['data']['atsign'];
        atSigns.add(atSign);
      } else {
        throw at_client.AtClientException.message(
            '${response.statusCode} ${response.reasonPhrase}');
      }
    }
    return atSigns;
  }

  /// Registers the [atSign] provided in the input to the provided [email]
  /// The `atSign` provided should be an unregistered and free atsign
  /// Returns true if the request to send the OTP was successful.
  /// Sends an OTP to the `email` provided.
  /// Throws [AtException] if [atSign] is invalid
  Future<bool> registerAtSign(String atSign, String email,
      {oldEmail, String authority = RegisterApiConstants.apiHostProd}) async {
    Response response =
        await _postRequest(authority, RegisterApiConstants.pathRegisterAtSign, {
      'atsign': atSign,
      'email': email,
      'oldEmail': oldEmail,
    });
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonDecoded = jsonDecode(response.body);
      bool sentSuccessfully =
          jsonDecoded['message'].toLowerCase().contains('success');
      return sentSuccessfully;
    } else {
      throw at_client.AtClientException.message(
          '${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// Registers the [atSign] provided in the input to the provided [email]
  /// The `atSign` provided should be an unregistered and free atsign
  /// Validates the OTP against the atsign and registers it to the provided email if OTP is valid.
  /// Returns the CRAM secret of the atsign which is registered.
  ///
  /// [confirmation] - Mandatory parameter for validateOTP API call. First request to be sent with confirmation as false, in this
  /// case API will return cram key if the user is new otherwise will return list of already existing atsigns.
  /// If the user already has existing atsigns user will have to select a listed atsign old/new and place a second call
  /// to the same API endpoint with confirmation set to true with previously received OTP. The second follow-up call
  /// is automated by this client using new atsign for user simplicity
  ///
  ///return value -  Case 1("verified") - the API has registered the atsign to provided email and CRAM key present in HTTP_RESPONSE Body.
  /// Case 2("follow-up"): User already has existing atsigns and new atsign registered successfully. To receive the CRAM key, follow-up by calling
  /// the API with one of the existing listed atsigns, with confirmation set to true.
  /// Case 3("retry"): Incorrect OTP send request again with correct OTP.
  /// Throws [AtException] if [atSign] or [otp] is invalid
  Future<String> validateOtp(String atSign, String email, String otp,
      {String confirmation = 'true',
      String authority = RegisterApiConstants.apiHostProd}) async {
    Response response =
        await _postRequest(authority, RegisterApiConstants.pathValidateOtp, {
      'atsign': atSign,
      'email': email,
      'otp': otp,
      'confirmation': confirmation,
    });
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonDecoded = jsonDecode(response.body);
      Map<String, dynamic> dataFromResponse = {};
      if (jsonDecoded.containsKey('data')) {
        dataFromResponse.addAll(jsonDecoded['data']);
      }
      if ((jsonDecoded.containsKey('message') &&
              (jsonDecoded['message'] as String)
                  .toLowerCase()
                  .contains('verified')) &&
          jsonDecoded.containsKey('cramkey')) {
        return jsonDecoded['cramkey'];
      } else if (jsonDecoded.containsKey('data') &&
          dataFromResponse.containsKey('newAtsign')) {
        return 'follow-up';
      } else if (jsonDecoded.containsKey('message') &&
          jsonDecoded['message'] ==
              'The code you have entered is invalid or expired. Please try again?') {
        return 'retry';
      } else if (jsonDecoded.containsKey('message') &&
          (jsonDecoded['message'] ==
              'Oops! You already have the maximum number of free atSigns. Please select one of your existing atSigns.')) {
        throw at_client.AtClientException.message(
            "Maximum free atsign limit reached");
      } else {
        throw at_client.AtClientException.message(
            '${response.statusCode} ${jsonDecoded['message']}');
      }
    } else {
      throw at_client.AtClientException.message(
          '${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// generic GET request
  Future<Response> _getRequest(String authority, String path) async {
    if (_ioClient == null) _createClient();
    Uri uri = Uri.https(authority, path);
    Response response = await _ioClient!.get(uri, headers: <String, String>{
      'Authorization': RegisterApiConstants.authorization,
      'Content-Type': RegisterApiConstants.contentType,
    });
    return response;
  }

  /// generic POST request
  Future<Response> _postRequest(
      String authority, String path, Map<String, String?> data) async {
    if (_ioClient == null) _createClient();

    Uri uri = Uri.https(authority, path);

    String body = json.encode(data);
    Response response = await _ioClient!.post(
      uri,
      body: body,
      headers: <String, String>{
        'Authorization': RegisterApiConstants.authorization,
        'Content-Type': RegisterApiConstants.contentType,
      },
    );

    // print('postRequest: ${response.body}');
    return response;
  }

  bool validateEmail(String email) {
    return RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);
  }

  bool validateVerificationCode(String otp) {
    return RegExp(r"^[a-zA-z0-9]{4}").hasMatch(otp);
  }
}