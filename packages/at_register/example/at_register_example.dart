import 'package:at_register/at_register.dart';

void main() async {
  String email = '<enter your email here>';
  RegisterParams params = RegisterParams()..email = email;

  GetFreeAtsign getFreeAtsignTask = GetFreeAtsign(params);
  RegisterTaskResult result = await getFreeAtsignTask.run();
  params.addFromJson(result.data);

  RegisterAtsign registerAtsignTask = RegisterAtsign(params);
  result = await registerAtsignTask.run();
  params.addFromJson(result.data);

  // verification code sent to email provided in the beginning
  // check the same email and enter that verification code through terminal/stdin
  params.otp = ApiUtil.readCliVerificationCode();
  ValidateOtp validateOtpTask = ValidateOtp(params);
  result = await validateOtpTask.run();
  if(result.apiCallStatus == ApiCallStatus.success){
    print(result.data[RegistrarConstants.cramKeyName]);
  } else {
    // this is the case where the email has existing atsigns
    // set task.params.confirmation to true, select an atsign (existing/new) from
    // the
    String newAtsign = result.data[RegistrarConstants.newAtsignName];
    validateOtpTask.registerParams.atsign = newAtsign;
    validateOtpTask.registerParams.confirmation = true;
    result = await validateOtpTask.run();
    print(result.data[RegistrarConstants.cramKeyName]);
  }
}