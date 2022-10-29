import 'package:at_commons/src/verb/verb_builder.dart';

/// Monitor builder generates a command that streams incoming notifications from the secondary server to
/// the current client.
/// ```
/// // Receives all of the notifications
///    var builder = MonitorVerbBuilder();
///
/// // Receives notifications for those keys that matches a specific regex
///    var builder = MonitorVerbBuilder()..regex = '.alice';
/// ```
class MonitorVerbBuilder implements VerbBuilder {
  bool auth = true;
  String? regex;
  int? lastNotificationTime;

  @override
  String buildCommand() {
    var monitorCommand = 'monitor';
    if (lastNotificationTime != null) {
      monitorCommand += ':${lastNotificationTime.toString()}';
    }
    if (regex != null) {
      monitorCommand += ' $regex';
    }
    monitorCommand += '\n';
    return monitorCommand;
  }

  @override
  bool checkParams() {
    return true;
  }
}
