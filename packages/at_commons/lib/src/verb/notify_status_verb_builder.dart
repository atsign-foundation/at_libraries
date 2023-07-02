import 'package:at_commons/src/verb/verb_builder.dart';

class NotifyStatusVerbBuilder implements VerbBuilder {
  /// Notification Id to query the status of notification
  String? notificationId;

  @override
  String buildCommand() {
    var command = 'notify:status:';
    if (notificationId != null) {
      command += '$notificationId\n';
    }
    return command;
  }

  @override
  bool checkParams() {
    var isValid = true;
    if (notificationId == null) {
      isValid = false;
    }
    return isValid;
  }
}
