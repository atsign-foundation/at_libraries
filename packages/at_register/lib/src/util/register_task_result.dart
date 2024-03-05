import 'dart:collection';

import 'api_call_status.dart';

class RegisterTaskResult {
  Map<String, dynamic> data = HashMap<String, dynamic>();

  late ApiCallStatus apiCallStatus;

  String? exceptionMessage;

  @override
  String toString() {
    return 'Data: $data | '
        'ApiCallStatus: ${apiCallStatus.name} | '
        'exception(if encountered): $exceptionMessage';
  }
}
