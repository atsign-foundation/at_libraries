import 'dart:async';
import 'dart:convert';

import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_logger.dart';
import 'package:http/http.dart' as http;

import 'package:at_register/at_register.dart';

/// Contains methods that actually perform the RegistrarAPI calls
/// and handle/process the response
class RegistrarApiAccessor {
  AtSignLogger logger = AtSignLogger('RegistrarApiAccessor');

  /// Returns a Future<List<String>> containing free available atSigns
  /// based on [count] provided as input.
  Future<String> getFreeAtSign(
      {String authority = RegistrarConstants.apiHostProd}) async {
    http.Response response = await ApiUtil.getRequest(
        authority, RegistrarConstants.getFreeAtSignApiPath);
    if (response.statusCode == 200) {
      String? atsign = jsonDecode(response.body)['data']['atsign'];
      if (atsign != null) {
        return atsign;
      }
    }
    throw AtRegisterException(
        'Could not fetch atsign | ${response.statusCode}:${response.reasonPhrase}');
  }

  /// Sends verification code to the provided [email] for the [atSign] provided
  ///
  /// The `atSign` provided should be an unregistered and free atsign
  ///
  /// Returns true if verification code is successfully delivered.
  ///
  /// Throws [AtRegisterException] if [atSign] is invalid
  ///
  /// Note: atsign will not be considered registered at this stage. The verification
  /// of verificationCode/otp will take place in [validateOtp]
  Future<bool> registerAtSign(String atSign, String email,
      {oldEmail, String authority = RegistrarConstants.apiHostProd}) async {
    final response = await ApiUtil.postRequest(
        authority, RegistrarConstants.registerAtSignApiPath, {
      'atsign': atSign,
      'email': email,
      'oldEmail': oldEmail,
    });
    if (response.statusCode == 200) {
      final jsonDecoded = jsonDecode(response.body) as Map<String, dynamic>;
      // will be set to true if API response contains message with 'success'
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
  /// ToDo: what would be the best place to Put the paragraph below
  ///
  /// [confirmation] - Mandatory parameter for validateOTP API call. First request to be sent with confirmation as FALSE, in this
  /// case API will return cram key if the user is new otherwise will return list of already existing atsigns.
  /// If the user already has existing atsigns user will have to select a listed atsign old/new and place a second call
  /// to the same API endpoint with confirmation set to true with previously received OTP. The second follow-up call
  /// is automated by this client using new atsign for user simplicity
  ///
  /// Returns:
  ///
  /// Case 1("verified") - the API has registered the atsign to provided email and CRAM key present in HTTP_RESPONSE Body.
  ///
  /// Case 2("follow-up"): User already has existing atsigns and new atsign
  /// registered successfully. To receive the CRAM key, retry the call with one
  /// of the existing listed atsigns and confirmation set to true.
  ///
  /// Case 3("retry"): Incorrect OTP send request again with correct OTP.
  ///
  /// Throws [AtException] if [atSign] or [otp] is invalid
  Future<ValidateOtpResult> validateOtp(String atSign, String email, String otp,
      {bool confirmation = true,
      String authority = RegistrarConstants.apiHostProd}) async {
    final response = await ApiUtil.postRequest(
        authority, RegistrarConstants.validateOtpApiPath, {
      'atsign': atSign,
      'email': email,
      'otp': otp,
      'confirmation': confirmation.toString(),
    });

    if (response.statusCode == 200) {
      ValidateOtpResult validateOtpResult = ValidateOtpResult();
      final jsonDecodedResponse = jsonDecode(response.body);
      _processValidateOtpApiResponse(jsonDecodedResponse, validateOtpResult);
      return validateOtpResult;
    } else {
      throw AtRegisterException(
          'Failed to Validate VerificationCode | ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  /// processes API response for [validateOtp] call and populates [result]
  void _processValidateOtpApiResponse(
      Map<String, dynamic> apiResponse, ValidateOtpResult result) {
    String? message = apiResponse['message'].toString().toLowerCase();
    if (apiResponse.containsKey('data')) {
      result.data.addAll(apiResponse['data'] as Map<String, dynamic>);
    }

    if (message == ValidateOtpStatus.verified.name &&
        apiResponse.containsKey(RegistrarConstants.cramKeyName)) {
      result.taskStatus = ValidateOtpStatus.verified;
    } else if (apiResponse.containsKey('data') &&
        apiResponse.containsKey(RegistrarConstants.newAtsignName)) {
      result.data[RegistrarConstants.fetchedAtsignListName] =
          apiResponse[RegistrarConstants.atsignName];
      result.taskStatus = ValidateOtpStatus.followUp;
    } else if (message ==
        'The code you have entered is invalid or expired. Please try again?') {
      result.taskStatus = ValidateOtpStatus.retry;
      result.exception = apiResponse['message'];
    } else if (message ==
        'Oops! You already have the maximum number of free atSigns. Please select one of your existing atSigns.') {
      throw MaximumAtsignQuotaException(
          'Maximum free atsign limit reached for current email');
    } else {
      throw AtRegisterException(message);
    }
  }

  /// Accepts a registered [atsign] as a parameter and sends a one-time verification code
  /// to the email that the atsign is registered with
  ///
  /// Throws an exception in the following cases:
  /// 1) HTTP 400 BAD_REQUEST
  /// 2) Invalid atsign
  Future<void> requestAuthenticationOtp(String atsign,
      {String authority = RegistrarConstants.apiHostProd}) async {
    final response = await ApiUtil.postRequest(authority,
        RegistrarConstants.requestAuthenticationOtpPath, {'atsign': atsign});
    final apiResponseMessage = jsonDecode(response.body)['message'];
    if (response.statusCode == 200 &&
        apiResponseMessage.contains('Sent Successfully')) {
      logger.info(
          'Successfully sent verification code to your registered e-mail');
      return;
    }
    throw AtRegisterException(
        'Unable to send verification code for authentication. | Cause: $apiResponseMessage');
  }

  /// Returns the cram key for an atsign by fetching it from the registrar API
  ///
  /// Accepts a registered [atsign], the verification code that was sent to
  /// the registered email
  ///
  /// Throws exception in the following cases: 1) HTTP 400 BAD_REQUEST
  Future<String> getCramKey(String atsign, String verificationCode,
      {String authority = RegistrarConstants.apiHostProd}) async {
    final response = await ApiUtil.postRequest(
        authority,
        RegistrarConstants.getCramKeyWithOtpPath,
        {'atsign': atsign, 'otp': verificationCode});
    final jsonDecodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      if (jsonDecodedBody['message'] == 'Verified') {
        String cram = jsonDecodedBody['cramkey'];
        cram = cram.split(':')[1];
        logger.info('CRAM Key fetched successfully');
        return cram;
      }
      // If API call status is HTTP.OK / 200, but the response message does not
      // contain 'Verified', that indicates incorrect verification provided by user
      throw InvalidVerificationCodeException(
          'Invalid verification code. Please enter a valid verification code');
    }
    throw InvalidDataException(jsonDecodedBody['message']);
  }

  /// calls utility methods from [RegistrarApiAccessor] that
  ///
  /// 1) send verification code to the registered email
  ///
  /// 2) fetch the CRAM key from registrar using the verification code
  Future<String> getCramUsingOtp(String atsign, String registrarUrl) async {
    await requestAuthenticationOtp(atsign, authority: registrarUrl);
    return await getCramKey(atsign, ApiUtil.readCliVerificationCode(),
        authority: registrarUrl);
  }
}
