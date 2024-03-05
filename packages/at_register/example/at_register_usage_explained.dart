import 'package:at_register/at_register.dart';

Future<void> main() async {
  RegisterParams params = RegisterParams()..email = 'abcd@email.com';
  RegistrarApiAccessor accessorInstance = RegistrarApiAccessor();

  /// Example for GetFreeAtsign task
  GetFreeAtsign getFreeAtsignTask =
      GetFreeAtsign(params, registrarApiAccessorInstance: accessorInstance);
  RegisterTaskResult getFreeAtsignResult = await getFreeAtsignTask.run();
  // api call status present in result.apiCallStatus
  print(getFreeAtsignResult.apiCallStatus);
  // all relevant data present in result.data which is a Map
  print(getFreeAtsignResult.data);

  // this step is optional
  // Can be used to propagates the data received in the current task to the next
  params.addFromJson(getFreeAtsignResult.data);
  // ----------------------------------------------------

  /// Example for RegisterAtsign task
  RegisterAtsign registerAtsignTask =
      RegisterAtsign(params, registrarApiAccessorInstance: accessorInstance);
  RegisterTaskResult registerAtsignResult = await registerAtsignTask.run();
  // registerAtsignResult.data should have a key named 'otpSent' which contains
  // true/false reg the status of verificationCodeSent to provided email
  print(registerAtsignResult.data[RegistrarConstants.otpSentName]);

  params.addFromJson(registerAtsignResult.data);
  // --------------------------------------------------------

  /// Example for ValidateOtp task
  ValidateOtp validateOtpTask =
      ValidateOtp(params, registrarApiAccessorInstance: accessorInstance);
  // Note: confirmation is set to false by default
  RegisterTaskResult validateOtpResult = await validateOtpTask.run();

  // CASE 1: if this is the first atsign for the provided email, CRAM should be
  // present in validateOtpResult.data with key RegistrarConstants.cramKeyName
  print(validateOtpResult.data[RegistrarConstants.cramKeyName]);

  // CASE 2: if this is not the first atsign, data contains the list of
  // existing atsigns registered to that email
  print(validateOtpResult.data[RegistrarConstants.fetchedAtsignListName]);
  // and the new atsign fetched in the previous task
  print(validateOtpResult.data[RegistrarConstants.newAtsignName]);
  // either select the newAtsign or one of the existing atsigns and re-run the
  // validateOtpTask but this time with confirmation set to true
  // now this will return a result with the cram key in result.data
  List<String> fetchedAtsignList =
      validateOtpResult.data[RegistrarConstants.fetchedAtsignListName];
  validateOtpTask.registerParams.atsign = fetchedAtsignList[0];
  validateOtpResult = await validateOtpTask.run();
  print(validateOtpResult.data[RegistrarConstants.cramKeyName]);

  // CASE 3: if the otp is incorrect, fetch the correct otp from user and re-run
  // the validateOtpTask
  validateOtpTask.registerParams.otp = 'AB14'; // correct otp
  validateOtpResult = await validateOtpTask.run();
}
