import 'api_call_status.dart';

class RegisterTaskResult {
  dynamic data;

  late ApiCallStatus apiCallStatus;

  String? exceptionMessage;

  @override
  String toString() {
    return 'Data: $data | '
        'ApiCallStatus: ${apiCallStatus.name} | '
        'exception(if encountered): $exceptionMessage';
  }
}
