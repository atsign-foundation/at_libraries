import 'package:at_onboarding_cli/src/register_cli/register.dart';

Future<void> main(List<String> args)async {
  Register register = Register();
  await register.main(args);
}