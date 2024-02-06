import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:http/http.dart' as http;

import '../../at_register.dart';

///class containing utilities to perform registration of a free atsign
class RegistrarApiCalls {
  /// Returns a Future<List<String>> containing free available atSigns of count provided as input.
  Future<List<String>> getFreeAtSigns(
      {int count = 1,
      String authority = RegistrarConstants.apiHostProd}) async {
    List<String> atSigns = <String>[];

    /// ToDo: discuss - what happens when getRequest does not generate a response
    http.Response response;
    for (int i = 0; i < count; i++) {
      // get request at my.atsign.com/api/app/v3/get-free-atsign/
      response = await ApiUtil.getRequest(
          authority, RegistrarConstants.pathGetFreeAtSign);
      if (response.statusCode == 200) {
        String atSign = jsonDecode(response.body)['data']['atsign'];
        atSigns.add(atSign);
      } else {
        throw AtRegisterException(
            '${response.statusCode} ${response.reasonPhrase}');
      }
    }
    return atSigns;
  }

  /// Registers the [atSign] provided in the input to the provided [email]
  ///
  /// The `atSign` provided should be an unregistered and free atsign
  ///
  /// Returns true if the request to send the OTP was successful.
  ///
  /// Sends an OTP to the `email` provided.
  ///
  /// Throws [AtRegisterException] if [atSign] is invalid
  Future<bool> registerAtSign(String atSign, String email,
      {oldEmail, String authority = RegistrarConstants.apiHostProd}) async {
    http.Response response = await ApiUtil.postRequest(
        authority, RegistrarConstants.pathRegisterAtSign, {
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
      throw AtRegisterException(
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
  /// Returns:
  ///
  /// Case 1("verified") - the API has registered the atsign to provided email and CRAM key present in HTTP_RESPONSE Body.
  ///
  /// Case 2("follow-up"): User already has existing atsigns and new atsign registered successfully. To receive the CRAM key, follow-up by calling
  /// the API with one of the existing listed atsigns, with confirmation set to true.
  ///
  /// Case 3("retry"): Incorrect OTP send request again with correct OTP.
  ///
  /// Throws [AtException] if [atSign] or [otp] is invalid
  Future<ValidateOtpResult> validateOtp(String atSign, String email, String otp,
      {bool confirmation = true,
      String authority = RegistrarConstants.apiHostProd}) async {
    http.Response response = await ApiUtil.postRequest(
        authority, RegistrarConstants.pathValidateOtp, {
      'atsign': atSign,
      'email': email,
      'otp': otp,
      'confirmation': confirmation.toString(),
    });

    ValidateOtpResult validateOtpResult = ValidateOtpResult();
    Map<String, dynamic> jsonDecodedResponse;
    if (response.statusCode == 200) {
      validateOtpResult.data = {};
      jsonDecodedResponse = jsonDecode(response.body);
      if (jsonDecodedResponse.containsKey('data')) {
        validateOtpResult.data.addAll(jsonDecodedResponse['data']);
      }
      _processApiResponse(jsonDecodedResponse, validateOtpResult);
    } else {
      throw AtRegisterException(
          '${response.statusCode} ${response.reasonPhrase}');
    }
    return validateOtpResult;
  }

  /// processes API response for ValidateOtp call
  void _processApiResponse(jsonDecodedResponse, result) {
    if ((jsonDecodedResponse.containsKey('message') &&
            (jsonDecodedResponse['message'].toString().toLowerCase()) ==
                'verified') &&
        jsonDecodedResponse.containsKey('cramkey')) {
      result.taskStatus = ValidateOtpStatus.verified;
      result.data['cramKey'] = jsonDecodedResponse['cramkey'];
    } else if (jsonDecodedResponse.containsKey('data') &&
        result.data.containsKey('newAtsign')) {
      result.taskStatus = ValidateOtpStatus.followUp;
    } else if (jsonDecodedResponse.containsKey('message') &&

        /// ToDo: discuss - compare entire message explicitly or keywords like (expired/invalid)
        jsonDecodedResponse['message'] ==
            'The code you have entered is invalid or expired. Please try again?') {
      result.taskStatus = ValidateOtpStatus.retry;
      result.exceptionMessage = jsonDecodedResponse['message'];
    } else if (jsonDecodedResponse.containsKey('message') &&
        (jsonDecodedResponse['message'] ==
            'Oops! You already have the maximum number of free atSigns. Please select one of your existing atSigns.')) {
      throw MaximumAtsignQuotaException(
          'Maximum free atsign limit reached for current email');
    } else {
      throw AtRegisterException('${jsonDecodedResponse['message']}');
    }
  }

  /// Accepts a registered [atsign] as a parameter and sends a one-time verification code
  /// to the email that the atsign is registered with
  /// Throws an exception in the following cases:
  /// 1) HTTP 400 BAD_REQUEST
  /// 2) Invalid atsign
  Future<void> requestAuthenticationOtp(String atsign,
      {String authority = RegistrarConstants.apiHostProd}) async {
    http.Response response = await ApiUtil.postRequest(authority,
        RegistrarConstants.requestAuthenticationOtpPath, {'atsign': atsign});
    String apiResponseMessage = jsonDecode(response.body)['message'];
    if (response.statusCode == 200) {
      if (apiResponseMessage.contains('Sent Successfully')) {
        stdout.writeln(
            '[Information] Successfully sent verification code to your registered e-mail');
        return;
      }
      throw AtRegisterException(
          'Unable to send verification code for authentication.\nCause: $apiResponseMessage');
    }
    throw AtRegisterException(apiResponseMessage);
  }

  /// Returns the cram key for an atsign by fetching it from the registrar API
  ///
  /// Accepts a registered [atsign], the verification code that was sent to
  /// the registered email
  ///
  /// Throws exception in the following cases: 1) HTTP 400 BAD_REQUEST
  Future<String> getCramKey(String atsign, String verificationCode,
      {String authority = RegistrarConstants.apiHostProd}) async {
    http.Response response = await ApiUtil.postRequest(
        authority,
        RegistrarConstants.getCramKeyWithOtpPath,
        {'atsign': atsign, 'otp': verificationCode});
    Map<String, dynamic> jsonDecodedBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (jsonDecodedBody['message'] == 'Verified') {
        String cram = jsonDecodedBody['cramkey'];
        cram = cram.split(':')[1];
        stdout.writeln('[Information] CRAM Key fetched successfully');
        return cram;
      }
      throw InvalidDataException(
          'Invalid verification code. Please enter a valid verification code');
    }
    throw InvalidDataException(jsonDecodedBody['message']);
  }

  /// calls utility methods from [RegistrarApiCalls] that
  ///
  /// 1) send verification code to the registered email
  ///
  /// 2) fetch the CRAM key from registrar using the verification code
  Future<String> getCramUsingOtp(String atsign, String registrarUrl) async {
    await requestAuthenticationOtp(atsign, authority: registrarUrl);
    return await getCramKey(atsign, ApiUtil.getVerificationCodeFromUser(),
        authority: registrarUrl);
  }
}
