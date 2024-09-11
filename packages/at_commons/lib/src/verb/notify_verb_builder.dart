import 'package:at_commons/src/keystore/at_key.dart';
import 'package:at_commons/src/verb/abstract_verb_builder.dart';
import 'package:at_commons/src/utils/string_utils.dart';
import 'package:uuid/uuid.dart';

import '../at_constants.dart';

import 'operation_enum.dart';
import 'verb_util.dart';

class NotifyVerbBuilder extends AbstractVerbBuilder {
  /// id for each notification.
  String id = Uuid().v4();

  /// Value of the key typically in string format. Images, files, etc.,
  /// must be converted to unicode string before storing.
  dynamic value;

  /// time in milliseconds after which a notification expires.
  int? ttln;

  OperationEnum? operation;

  /// priority of the notification
  PriorityEnum? priority;

  /// strategy in processing the notification
  StrategyEnum? strategy;

  /// type of notification
  MessageTypeEnum? messageType;

  /// The notifier of the notification. Defaults to system.
  String notifier = AtConstants.system;

  /// Latest N notifications to notify. Defaults to 1
  int? latestN;

  @override
  String buildCommand() {
    StringBuffer sb = StringBuffer();
    sb.write('notify:id:$id');

    if (operation != null) {
      sb.write(':${getOperationName(operation)}');
    }
    if (messageType != null) {
      sb.write(':messageType:${getMessageType(messageType)}');
    }
    if (priority != null) {
      sb.write(':priority:${getPriority(priority)}');
    }
    if (strategy != null) {
      sb.write(':strategy:${getStrategy(strategy)}');
    }
    if (latestN != null) {
      sb.write(':latestN:$latestN');
    }
    sb.write(':notifier:$notifier');
    if (ttln != null) {
      sb.write(':ttln:$ttln');
    }

    // Add in all of the metadata parameters in atProtocol command format
    sb.write(_toAtProtocolFragment(atKey.metadata));

    if (atKey.sharedWith != null) {
      sb.write(':${VerbUtil.formatAtSign(atKey.sharedWith)}');
    }

    if (atKey.metadata.isPublic == true) {
      sb.write(':public');
    }
    sb.write(':${atKey.key}');

    if (atKey.sharedBy != null) {
      sb.write('${VerbUtil.formatAtSign(atKey.sharedBy)}');
    }
    if (value != null) {
      sb.write(':$value');
    }

    sb.write('\n');

    return sb.toString();
  }

  // temporary method till isEncrypted flag changes are done for update verb.
  // TODO Remove this and use at_key.metadata.toProtocolFragment
  String _toAtProtocolFragment(Metadata metadata) {
    StringBuffer sb = StringBuffer();

    // NB The order of the verb parameters is important - it MUST match the order
    // in the regular expressions [VerbSyntax.update] and [VerbSyntax.update_meta]
    if (metadata.ttl != null) {
      sb.write(':ttl:${metadata.ttl}');
    }
    if (metadata.ttb != null) {
      sb.write(':ttb:${metadata.ttb}');
    }
    if (metadata.ttr != null) {
      sb.write(':ttr:${metadata.ttr}');
    }
    if (metadata.ccd != null) {
      sb.write(':ccd:${metadata.ccd}');
    }
    if (metadata.dataSignature.isNotNullOrEmpty) {
      sb.write(':${AtConstants.publicDataSignature}:${metadata.dataSignature}');
    }
    if (metadata.sharedKeyStatus.isNotNullOrEmpty) {
      sb.write(':${AtConstants.sharedKeyStatus}:${metadata.sharedKeyStatus}');
    }
    if (metadata.isBinary) {
      sb.write(':isBinary:${metadata.isBinary}');
    }

    sb.write(':isEncrypted:${metadata.isEncrypted}');

    if (metadata.sharedKeyEnc.isNotNullOrEmpty) {
      sb.write(':${AtConstants.sharedKeyEncrypted}:${metadata.sharedKeyEnc}');
    }
    // ignore: deprecated_member_use_from_same_package
    if (metadata.pubKeyCS.isNotNullOrEmpty) {
      // ignore: deprecated_member_use_from_same_package
      sb.write(
          ':${AtConstants.sharedWithPublicKeyCheckSum}:${metadata.pubKeyCS}');
    }
    if (metadata.pubKeyHash != null) {
      sb.write(
          ':${AtConstants.sharedWithPublicKeyHashValue}:${metadata.pubKeyHash!.hash}');
      sb.write(
          ':${AtConstants.sharedWithPublicKeyHashAlgo}:${metadata.pubKeyHash!.publicKeyHashingAlgo.name}');
    }
    if (metadata.encoding.isNotNullOrEmpty) {
      sb.write(':${AtConstants.encoding}:${metadata.encoding}');
    }
    if (metadata.encKeyName.isNotNullOrEmpty) {
      sb.write(':${AtConstants.encryptingKeyName}:${metadata.encKeyName}');
    }
    if (metadata.encAlgo.isNotNullOrEmpty) {
      sb.write(':${AtConstants.encryptingAlgo}:${metadata.encAlgo}');
    }
    if (metadata.ivNonce.isNotNullOrEmpty) {
      sb.write(':${AtConstants.ivOrNonce}:${metadata.ivNonce}');
    }
    if (metadata.skeEncKeyName.isNotNullOrEmpty) {
      sb.write(
          ':${AtConstants.sharedKeyEncryptedEncryptingKeyName}:${metadata.skeEncKeyName}');
    }
    if (metadata.skeEncAlgo.isNotNullOrEmpty) {
      sb.write(
          ':${AtConstants.sharedKeyEncryptedEncryptingAlgo}:${metadata.skeEncAlgo}');
    }
    return sb.toString();
  }

  @override
  bool checkParams() {
    var isValid = true;
    if ((atKey.key.isNotEmpty) ||
        (atKey.metadata.isPublic == true && atKey.sharedWith != null)) {
      isValid = false;
    }
    return isValid;
  }
}
