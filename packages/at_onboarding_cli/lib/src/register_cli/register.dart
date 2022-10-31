import 'dart:collection';
import 'dart:io';

import 'package:args/args.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/activate_cli/activate_cli.dart'
    as activate_cli;
import 'package:at_onboarding_cli/src/util/api_call_status.dart';
import 'package:at_onboarding_cli/src/util/register_api_constants.dart';
import 'package:at_onboarding_cli/src/util/register_api_result.dart';
import 'package:at_onboarding_cli/src/util/register_api_task.dart';
import 'package:at_utils/at_logger.dart';

///Class containing logic to register a free atsign to email provided through [args] by utilizing methods defined in [RegisterUtil]
///Requires List<String> args containing the following arguments: email
///User can optionally choose the staging environment by adding "-n staging" to the args [for testing only]
class Register {
  static AtSignLogger logger = AtSignLogger('Register Cli');
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
      logger.severe(argParser.usage);
      exit(0);
    }

    if (!argResults.wasParsed('email')) {
      logger.severe('-e (or) --email is required.');
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

    //create stream of tasks each of type [RegisterApiTask] and then call start on the stream of tasks
    await RegistrationFlow(params, RegisterUtil())
        .add(GetFreeAtsign())
        .add(RegisterAtsign())
        .add(ValidateOtp())
        .start();

    //call activate_cli with the cramkey acquired from registration process
    logger.info('Activating you atsign: ${params['atsign']}');
    activate_cli.main([
      '-a',
      params['atsign']!,
      '-c',
      params['cramkey']!,
      '-r',
      argResults['environment'] == 'staging' ? 'root.atsign.wtf' : 'root.atsign.org'
    ]);
  }
}

///class that handles multiple tasks of type [RegisterApiTask]
///Initialized with a params map that needs to be populated with - email and api host address
///[add] method can be used to add tasks[RegisterApiTask] to the [processFlow]
///[start] needs to becalled after all required tasks are added to the [processFlow]
class RegistrationFlow {
  List<RegisterApiTask> processFlow = [];
  RegisterApiResult result = RegisterApiResult();
  late RegisterUtil registerUtil;
  Map<String, String> params;

  RegistrationFlow(this.params, this.registerUtil);

  RegistrationFlow add(RegisterApiTask task) {
    processFlow.add(task);
    return this;
  }

  Future<void> start() async {
    for (RegisterApiTask task in processFlow) {
      task.init(params, registerUtil);
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

///This is a [RegisterApiTask] that fetches a free atsign
///throws [AtException] with concerned message which was encountered in the HTTP GET/POST request
class GetFreeAtsign extends RegisterApiTask {
  @override
  Future<RegisterApiResult> run() async {
    Register.logger.info('Gettting free atsign ...');
    try {
      List<String> atsignList =
          await registerUtil.getFreeAtSigns(authority: params['authority']!);
      result.data['atsign'] = atsignList[0];
      Register.logger.info('Got atsign: ${atsignList[0]}');
      result.apiCallStatus = ApiCallStatus.success;
    } on Exception catch (e) {
      result.exceptionMessage = e.toString();
      result.apiCallStatus =
          shouldRetry() ? ApiCallStatus.retry : ApiCallStatus.failure;
    }

    return result;
  }
}

///This is a [RegisterApiTask] that registers a free atsign fetched in [GetFreeAtsign] to the email provided as args
///throws [AtException] with concerned message which was encountered in the HTTP GET/POST request
class RegisterAtsign extends RegisterApiTask {
  @override
  Future<RegisterApiResult> run() async {
    Register.logger.info('Sending otp to: ${params['email']}');
    try {
      result.data['otpSent'] = (await registerUtil.registerAtSign(
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

///This is a [RegisterApiTask] that validates the otp which was sent as a part of [RegisterAtsign] to email provided in args
///throws [AtException] with concerned message which was encountered in the HTTP GET/POST request
class ValidateOtp extends RegisterApiTask {
  @override
  void init(Map<String, String> params, RegisterUtil registerUtil) {
    params['confirmation'] = 'false';
    this.params = params;
    this.registerUtil = registerUtil;
    result.data = HashMap<String, String>();
  }

  @override
  Future<RegisterApiResult> run() async {
    if (params['otp'] == null) {
      Register.logger.shout('Enter otp received on: ${params['email']}');
      params['otp'] = stdin.readLineSync()!;
    }
    Register.logger.info('Validating otp ...');
    try {
      String apiResponse = await registerUtil.validateOtp(
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
        result.data['otp'] = params['otp'];
        result.apiCallStatus = ApiCallStatus.retry;
      } else if (apiResponse.startsWith("@")) {
        result.data['cramkey'] = apiResponse.split(":")[1];
        Register.logger.shout('Your cram secret: ' + result.data['cramkey']);
        Register.logger.info("Registration complete.");
        result.apiCallStatus = ApiCallStatus.success;
      }
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