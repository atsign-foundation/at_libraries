import 'package:at_commons/at_builders.dart';

class NotifyListVerbBuilder implements VerbBuilder {
  String? fromDate;
  String? toDate;
  String? regex;

  @override
  String buildCommand() {
    var command = 'notify:list';
    if (fromDate != null) {
      command += ':$fromDate';
    }
    if (toDate != null) {
      command += ':$toDate';
    }
    if (regex != null) {
      command += ':$regex';
    }
    return command += '\n';
  }

  @override
  bool checkParams() {
    var isValid = true;
    try {
      if (DateTime.parse(toDate!).millisecondsSinceEpoch <
          DateTime.parse(fromDate!).millisecondsSinceEpoch) {
        isValid = false;
      }
    } on Exception {
      isValid = false;
    }
    return isValid;
  }
}
