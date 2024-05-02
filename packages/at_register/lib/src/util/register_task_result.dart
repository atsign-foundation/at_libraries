import 'dart:collection';

import 'api_call_status.dart';

class RegisterTaskResult {
  Map<String, dynamic> data = HashMap<String, dynamic>();

  late ApiCallStatus apiCallStatus;

  List<String>? fetchedAtsignList;

  Exception? exception;

  @override
  String toString() {
    return 'Data: $data | '
        'ApiCallStatus: ${apiCallStatus.name} | '
        'exception(if encountered): $exception';
  }
}
