import 'dart:collection';
import 'dart:io';

import 'package:args/args.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/util/api_call_status.dart';
import 'package:at_onboarding_cli/src/util/register_api_constants.dart';
import 'package:at_onboarding_cli/src/util/register_api_result.dart';
import 'package:at_onboarding_cli/src/util/register_api_task.dart';

class Register {
  Future<void> main(List<String> args) async {
    Map<String, String> params = HashMap<String, String>();

    final argParser = ArgParser()
      ..addOption('email', abbr: 'e', help: 'email to register atsign with')
      ..addOption('environment',
          abbr: 'n',
          defaultsTo: 'production',
          help: 'use production/staging env')
      ..addFlag('help',
          abbr: 'h', help: 'Usage instructions', negatable: false);

    ArgResults argResults = argParser.parse(args);

    if (argResults.wasParsed('help')) {
      print(argParser.usage);
      exit(0);
    }

    if (!argResults.wasParsed('email')) {
      stderr.writeln('-e (or) --email is required.');
      exit(1);
    } else {
      params['email'] = argResults['email'];
    }

    if (argResults.wasParsed('environment')) {
      params['authority'] = argResults['environment'] == 'staging'
          ? RegisterApiConstants.apiHostStaging
          : RegisterApiConstants.apiHostProd;
    } else {
      params['authority'] = RegisterApiConstants.apiHostProd;
    }

    await RegistrationFlow(params)
        .add(GetFreeAtsign())
        .add(RegisterAtsign())
        .add(ValidateOtp())
        .start();
  }
}

class RegistrationFlow {
  List<RegisterApiTask> processFlow = [];
  RegisterApiResult result = RegisterApiResult();
  Map<String, String> params;

  RegistrationFlow(this.params);

  RegistrationFlow add(RegisterApiTask task) {
    processFlow.add(task);
    return this;
  }

  Future<void> start() async {
    for (RegisterApiTask task in processFlow) {
      task.init(params);
      result = await task.run();
      if (result.apiCallStatus == ApiCallStatus.retry) {
        while (
            task.shouldRetry() && result.apiCallStatus == ApiCallStatus.retry) {
          result = await task.run();
          task.retryCount++;
        }
      }
      if (result.apiCallStatus == ApiCallStatus.success) {
        params.addAll(result.data);
      } else {
        throw AtClientException.message(result.exceptionMessage);
      }
    }
  }
}

class GetFreeAtsign extends RegisterApiTask {
  @override
  Future<RegisterApiResult> run() async {
    stdout.writeln('Gettting free atsign ...');
    try {
      List<String> atsignList =
          await RegisterUtil.getFreeAtSigns(authority: params['authority']!);
      result.data['atsign'] = atsignList[0];
      stdout.writeln('Got atsign: ${atsignList[0]}');
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }

    return result;
  }
}

class RegisterAtsign extends RegisterApiTask {
  @override
  Future<RegisterApiResult> run() async {
    stdout.writeln('Sending otp to: ${params['email']}');
    try {
      result.data['otpSent'] = (await RegisterUtil.registerAtSign(
              params['atsign']!, params['email']!,
              authority: params['authority']!))
          .toString();
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}

class ValidateOtp extends RegisterApiTask {
  @override
  Future<RegisterApiResult> run() async {
    params['confirmation'] = 'false';
    if (params['otp'] == null) {
      stdout.writeln('Enter otp received on: ${params['email']}');
      params['otp'] = stdin.readLineSync()!;
    }
    stdout.writeln('Validating otp ...');
    try {
      print(params);
      String apiResponse = await RegisterUtil.validateOtp(
          params['atsign']!, params['email']!, params['otp']!,
          confirmation: params['confirmation']!,
          authority: params['authority']!);
      if (apiResponse == 'retry') {
        stderr.writeln("Incorrect OTP!!! Please re-enter your OTP");
        params['otp'] = stdin.readLineSync()!;
        result.apiCallStatus = ApiCallStatus.retry;
        result.exceptionMessage =
            'Incorrect otp entered 3 times. Max retries reached.';
      } else if (apiResponse == 'follow-up') {
        params.update('confirmation', (value) => 'true');
        result.apiCallStatus = ApiCallStatus.retry;
      } else if (apiResponse.startsWith("@")) {
        result.data.put("cram", apiResponse.split(":")[1]);
        stdout.writeln("your cram secret: " + result.data.get("cram"));
        stdout.writeln("Done.");
        result.apiCallStatus = ApiCallStatus.success;
      }
      result.data['otp'] = params['otp'];
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }
    return result;
  }
}

Future<void> main(List<String> args) async {
  Register register = Register();
  await register.main(args);
}
