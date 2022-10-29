import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/verb_builder.dart';
import 'package:uuid/uuid.dart';

class NotifyVerbBuilder implements VerbBuilder {
  /// id for each notification.
  String id = Uuid().v4();

  /// Key that represents a user's information. e.g phone, location, email etc.,
  String? atKey;

  /// Value of the key typically in string format. Images, files, etc.,
  /// must be converted to unicode string before storing.
  dynamic value;

  /// AtSign to whom [atKey] has to be shared.
  String? sharedWith;

  /// AtSign of the client user calling this builder.
  String? sharedBy;

  /// if [isPublic] is true, then [atKey] is accessible by all atSigns.
  /// if [isPublic] is false, then [atKey] is accessible either by [sharedWith] or [sharedBy]
  bool isPublic = false;

  /// time in milliseconds after which [atKey] expires.
  int? ttl;

  /// time in milliseconds after which a notification expires.
  int? ttln;

  /// time in milliseconds after which [atKey] becomes active.
  int? ttb;

  /// time in milliseconds to refresh [atKey].
  int? ttr;

  OperationEnum? operation;

  /// priority of the notification
  PriorityEnum? priority;

  /// strategy in processing the notification
  StrategyEnum? strategy;

  /// type of notification
  MessageTypeEnum? messageType;

  /// The notifier of the notification. Defaults to system.
  String notifier = SYSTEM;

  /// Latest N notifications to notify. Defaults to 1
  int? latestN;

  bool? ccd;

  /// Represents if the [MessageTypeEnum.text] is encrypted or not. Setting to false to preserve
  /// backward compatibility.
  bool isTextMessageEncrypted = false;

  /// Will be set only when [sharedWith] is set. Will be encrypted using the public key of [sharedWith] atsign
  String? sharedKeyEncrypted;

  /// checksum of the the public key of [sharedWith] atsign. Will be set only when [sharedWith] is set.
  String? pubKeyChecksum;

  @override
  String buildCommand() {
    var command = 'notify:id:$id:';

    if (operation != null) {
      command += '${getOperationName(operation)}:';
    }
    if (messageType != null) {
      command += 'messageType:${getMessageType(messageType)}:';
    }
    if (priority != null) {
      command += 'priority:${getPriority(priority)}:';
    }
    if (strategy != null) {
      command += 'strategy:${getStrategy(strategy)}:';
    }
    if (latestN != null) {
      command += 'latestN:$latestN:';
    }
    command += 'notifier:$notifier:';
    if (ttl != null) {
      command += 'ttl:$ttl:';
    }
    if (ttln != null) {
      command += 'ttln:$ttln:';
    }
    if (ttb != null) {
      command += 'ttb:$ttb:';
    }
    if (ttr != null) {
      ccd ??= false;
      command += 'ttr:$ttr:ccd:$ccd:';
    }
    if (isTextMessageEncrypted) {
      command += '$IS_ENCRYPTED:$isTextMessageEncrypted:';
    }

    if (sharedKeyEncrypted != null) {
      command += '$SHARED_KEY_ENCRYPTED:$sharedKeyEncrypted:';
    }
    if (pubKeyChecksum != null) {
      command += '$SHARED_WITH_PUBLIC_KEY_CHECK_SUM:$pubKeyChecksum:';
    }

    if (sharedWith != null) {
      command += '${VerbUtil.formatAtSign(sharedWith)}:';
    }

    if (isPublic) {
      command += 'public:';
    }
    command += atKey!;

    if (sharedBy != null) {
      command += '${VerbUtil.formatAtSign(sharedBy)}';
    }
    if (value != null) {
      command += ':$value';
    }

    return '$command\n';
  }

  @override
  bool checkParams() {
    var isValid = true;
    if ((atKey == null) || (isPublic == true && sharedWith != null)) {
      isValid = false;
    }
    return isValid;
  }
}
