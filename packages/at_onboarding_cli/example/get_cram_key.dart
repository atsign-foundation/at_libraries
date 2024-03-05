import 'package:args/args.dart';
import 'package:at_register/at_register.dart';

import 'util/custom_arg_parser.dart';

Future<void> main(args) async {
  final argResults = CustomArgParser(getArgParser()).parse(args);

  // this step sends an OTP to the registered email
  await RegistrarApiAccessor().requestAuthenticationOtp(
      argResults['atsign']); // requires a registered atsign

  // the following step validates the email that was sent in the above step
  String? verificationCode = ApiUtil.readCliVerificationCode();
  String cramKey = await RegistrarApiAccessor().getCramKey(argResults['atsign'],
      verificationCode); // verification code received on the registered email

  print('Your cram key is: $cramKey');
}

ArgParser getArgParser() {
  return ArgParser()
    ..addOption('atsign',
        abbr: 'a', help: 'the atsign you would like to auth with')
    ..addFlag('help', abbr: 'h', help: 'Usage instructions', negatable: false);
}
