import 'dart:collection';

import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/verb_builder.dart';

/// Monitor builder generates a command that streams incoming notifications from the secondary server to
/// the current client. See also [VerbSyntax.monitor]
class MonitorVerbBuilder implements VerbBuilder {
  @Deprecated('not used')
  bool auth = true;

  String? _regex;

  /// The regular expression to be used when building the monitor command.
  /// When [regex] is supplied, server will send notifications which match the regex. If [strict]
  /// is true, then only those regex-matching notifications will be sent. If [strict] is false,
  /// then other 'control' notifications (e.g. the statsNotification) which don't necessarily
  /// match the [regex] will also be sent
  String? get regex => _regex;
  set regex(String? r) {
    if (r != null && r.trim().isEmpty) {
      r = null;
    }
    _regex = r;
  }

  /// The timestamp, in milliseconds since epoch, to be used when building the monitor command.
  /// When [lastNotificationTime] is supplied, server will only send notifications received at
  /// or after that timestamp
  int? lastNotificationTime;

  /// Whether this monitor command is to be built with the 'strict' flag or not.
  /// When [strict] is true, server will only send notifications which match the [regex]; no other
  /// 'control' notifications such as statsNotifications will be sent on this connection unless
  /// they match the [regex]
  bool strict = false;

  /// Whether this monitor command is to be built with the 'multiplexed' flag or not.
  /// When [multiplexed] is true, the server will understand that this is a connection
  /// which the client is using not just for notifications but also for request-response
  /// interactions. In this case, the server will only send notifications once there is
  /// no request currently in progress
  bool multiplexed = false;

  @override
  String buildCommand() {
    var monitorCommand = 'monitor';
    if (strict) {
      monitorCommand += ':strict';
    }
    if (multiplexed) {
      monitorCommand += ':multiplexed';
    }
    if (lastNotificationTime != null) {
      monitorCommand += ':$lastNotificationTime';
    }
    if (regex != null && regex!.trim().isNotEmpty) {
      monitorCommand += ' $regex';
    }
    monitorCommand += '\n';
    return monitorCommand;
  }

  @override
  bool checkParams() {
    return true;
  }

  /// Create a MonitorVerbBuilder from an atProtocol command string
  static MonitorVerbBuilder getBuilder(String command) {
    if (command != command.trim()) {
      throw IllegalArgumentException(
          'Commands may not have leading or trailing whitespace');
    }
    HashMap<String, String?>? verbParams =
        (VerbUtil.getVerbParam(VerbSyntax.monitor, command));
    if (verbParams == null) {
      throw InvalidSyntaxException('Command does not match the monitor syntax');
    }

    var builder = MonitorVerbBuilder();
    builder.strict = verbParams[MONITOR_STRICT_MODE] == MONITOR_STRICT_MODE;
    builder.multiplexed =
        verbParams[MONITOR_MULTIPLEXED_MODE] == MONITOR_MULTIPLEXED_MODE;
    builder.regex = verbParams[MONITOR_REGEX];
    builder.lastNotificationTime = verbParams[EPOCH_MILLIS] == null
        ? null
        : int.parse(verbParams[EPOCH_MILLIS]!);

    return builder;
  }

  @override
  String toString() {
    return 'MonitorVerbBuilder{regex: $regex, lastNotificationTime: $lastNotificationTime, strict: $strict, multiplexed: $multiplexed}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitorVerbBuilder &&
          runtimeType == other.runtimeType &&
          regex == other.regex &&
          lastNotificationTime == other.lastNotificationTime &&
          strict == other.strict &&
          multiplexed == other.multiplexed;

  @override
  int get hashCode =>
      regex.hashCode ^
      lastNotificationTime.hashCode ^
      strict.hashCode ^
      multiplexed.hashCode;
}
