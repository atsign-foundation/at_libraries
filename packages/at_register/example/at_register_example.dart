import 'package:at_register/at_register.dart';

void main() async {
  String email = '<enter your email here>';
  RegisterParams registerParams = RegisterParams()..email = email;

  GetFreeAtsign getFreeAtsignTask = GetFreeAtsign();
  RegisterTaskResult result = await getFreeAtsignTask.run(registerParams);
  registerParams.addFromJson(result.data);

  RegisterAtsign registerAtsignTask = RegisterAtsign();
  result = await registerAtsignTask.run(registerParams);
  registerParams.addFromJson(result.data);

  // verification code sent to email provided in the beginning
  // check the same email and enter that verification code through terminal/stdin
  registerParams.otp = ApiUtil.readCliVerificationCode();
  ValidateOtp validateOtpTask = ValidateOtp();
  result = await validateOtpTask.run(registerParams);
  if (result.apiCallStatus == ApiCallStatus.success) {
    print(result.data[RegistrarConstants.cramKeyName]);
  } else {
    // this is the case where the email has existing atsigns
    // set task.params.confirmation to true, select an atsign (existing/new)
    // from the list of atsigns returned in the previous call(ValidateOtp with confirmation set to false)
    String newAtsign = result.data[RegistrarConstants.newAtsignName];
    registerParams.atsign = newAtsign;
    registerParams.confirmation = true;
    result = await validateOtpTask.run(registerParams);
    print(result.data[RegistrarConstants.cramKeyName]);
  }
}
