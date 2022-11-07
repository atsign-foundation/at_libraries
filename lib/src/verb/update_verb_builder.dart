import 'dart:collection';
import 'dart:convert';

import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/utils/string_utils.dart';
import 'package:at_commons/src/verb/abstract_verb_builder.dart';

/// Update builder generates a command to update [value] for a key [atKey] in the secondary server of [sharedBy].
/// Use [getBuilder] method if you want to convert command to a builder.
///
///  * Setting a public value for the key 'phone'
///
///  * When isPublic is set to true, throws [InvalidAtKeyException] if isLocal is set to true or sharedWith is populated
///```dart
///  var updateBuilder = UpdateVerbBuilder()
///  ..isPublic=true
///  ..key='phone'
///  ..sharedBy='bob'
///  ..value='+1-1234';
///```
///
///   * @bob setting a value for the key 'phone' to share with @alice
///
///   * When sharedWith is populated, throws [InvalidAtKeyException] if isLocal or isPublic is set to true
///```dart
///  var updateBuilder = UpdateVerbBuilder()
///  ..sharedWith=’alice’
///  ..key='phone'
///  ..sharedBy='bob'
///  ..value='+1-5678';
///```
///
/// * Creating a local key for storing data that does not sync
///
/// * When isLocal is set to true, throws [InvalidAtKeyException] if isPublic is set to true or sharedWith is populated
///```dart
///  var updateBuilder = UpdateVerbBuilder()
///                      ..isLocal = true
///                      ..key = 'preferences'
///                      ..sharedBy = '@bob'
///                      ..value = jsonEncode(myPrefObj)
///```
class UpdateVerbBuilder extends AbstractVerbBuilder {
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

  /// time in milliseconds after which [atKey] becomes active.
  int? ttb;

  /// time in milliseconds to refresh [atKey].
  int? ttr;

  ///boolean variable to enable/disable cascade delete
  bool? ccd;

  bool? isBinary;

  /// boolean variable to indicate if the value is encrypted.
  /// True indicates encrypted value
  /// False indicates unencrypted value
  bool? isEncrypted;

  /// Signed signature with atsign's private key, if isPublic is true
  String? dataSignature;

  String? operation;

  bool isJson = false;

  String? sharedKeyStatus;

  /// Will be set only when [sharedWith] is set. Will be encrypted using the public key of [sharedWith] atsign
  String? sharedKeyEncrypted;

  /// checksum of the the public key of [sharedWith] atsign. Will be set only when [sharedWith] is set.
  String? pubKeyChecksum;

  ///Indicates if the public data is encoded.
  ///If the public data contains new line (\n) character, the data will be encoded and encoding will be set to type of encoding
  String? encoding;

  /// Indicates if the key is local
  /// If the key is local, the key does not sync between cloud and local secondary
  bool isLocal = false;

  @override
  String buildCommand() {
    if (isJson) {
      var updateParams = UpdateParams();
      var key = '';
      if (sharedWith != null) {
        key += '${VerbUtil.formatAtSign(sharedWith)}:';
      }
      key += atKey!;
      if (sharedBy != null) {
        key += '${VerbUtil.formatAtSign(sharedBy)}';
      }
      updateParams.atKey = key;
      updateParams.value = value;
      updateParams.sharedBy = sharedBy;
      updateParams.sharedWith = sharedWith;
      final metadata = Metadata();
      metadata.ttr = ttr;
      metadata.ttb = ttb;
      metadata.ttl = ttl;
      metadata.dataSignature = dataSignature;
      if (isEncrypted != null) {
        metadata.isEncrypted = isEncrypted!;
      }
      metadata.ccd = ccd;
      metadata.isPublic = isPublic;
      metadata.sharedKeyStatus = sharedKeyStatus;
      metadata.sharedKeyEnc = sharedKeyEncrypted;
      metadata.sharedKeyStatus = sharedKeyStatus;
      metadata.encoding = encoding;
      updateParams.metadata = metadata;
      var json = updateParams.toJson();
      var command = 'update:json:${jsonEncode(json)}\n';
      return command;
    }
    var command = 'update';
    command += buildMetadataString();
    command += ':${buildKey()}';
    command += ' $value\n';
    return command;
  }

  @override
  buildKey() {
    super.atKeyObj
      ..key = atKey
      ..sharedWith = VerbUtil.formatAtSign(sharedWith)
      ..sharedBy = VerbUtil.formatAtSign(sharedBy)
      ..metadata = (Metadata()
        ..ttl = ttl
        ..ttb = ttb
        ..ttr = ttr
        ..ccd = ccd
        ..isBinary = isBinary
        ..isPublic = isPublic
        ..isEncrypted = isEncrypted
        ..sharedKeyEnc = sharedKeyEncrypted
        ..pubKeyCS = pubKeyChecksum
        ..sharedKeyStatus = sharedKeyStatus)
      ..isLocal = isLocal;
    // If validation is successful, build the command and returns;
    // else throws exception.
    validateKey();
    return super.buildKey();
  }

  String buildCommandForMeta() {
    var command = 'update:meta';
    command += ':${buildKey()}';
    command += buildMetadataString();
    command += '\n';
    return command;
  }

  static UpdateVerbBuilder? getBuilder(String command) {
    var builder = UpdateVerbBuilder();
    HashMap<String, String?>? verbParams;
    if (command.contains(UPDATE_META)) {
      verbParams = VerbUtil.getVerbParam(VerbSyntax.update_meta, command);
      builder.operation = UPDATE_META;
    } else {
      verbParams = VerbUtil.getVerbParam(VerbSyntax.update, command);
    }
    if (verbParams == null) {
      return null;
    }
    builder.isPublic = command.contains('public:');
    builder.sharedWith = VerbUtil.formatAtSign(verbParams[FOR_AT_SIGN]);
    builder.sharedBy = VerbUtil.formatAtSign(verbParams[AT_SIGN]);
    builder.atKey = verbParams[AT_KEY];
    builder.value = verbParams[AT_VALUE];
    if (builder.value is String) {
      builder.value = VerbUtil.replaceNewline(builder.value);
    }
    if (verbParams[AT_TTL] != null) {
      builder.ttl = int.parse(verbParams[AT_TTL]!);
    }
    if (verbParams[AT_TTB] != null) {
      builder.ttb = int.parse(verbParams[AT_TTB]!);
    }
    if (verbParams[AT_TTR] != null) {
      builder.ttr = int.parse(verbParams[AT_TTR]!);
    }
    if (verbParams[CCD] != null) {
      builder.ccd = _getBoolVerbParams(verbParams[CCD]!);
    }
    if (verbParams[PUBLIC_DATA_SIGNATURE] != null) {
      builder.dataSignature = verbParams[PUBLIC_DATA_SIGNATURE];
    }
    if (verbParams[IS_BINARY] != null) {
      builder.isBinary = _getBoolVerbParams(verbParams[IS_BINARY]!);
    }
    if (verbParams[IS_ENCRYPTED] != null) {
      builder.isEncrypted = _getBoolVerbParams(verbParams[IS_ENCRYPTED]!);
    }
    if (verbParams[SHARED_KEY_ENCRYPTED] != null) {
      builder.sharedKeyEncrypted = verbParams[SHARED_KEY_ENCRYPTED];
    }
    if (verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM] != null) {
      builder.sharedKeyEncrypted = verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM];
    }
    return builder;
  }

  @override
  bool checkParams() {
    var isValid = true;
    if ((atKey == null || value == null) ||
        (isPublic == true && sharedWith != null)) {
      isValid = false;
    }
    return isValid;
  }

  static bool _getBoolVerbParams(String arg1) {
    if (arg1.toLowerCase() == 'true') {
      return true;
    }
    return false;
  }

  String buildMetadataString() {
    String metadataKey = '';

    if (ttl != null) {
      metadataKey += ':ttl:$ttl';
    }
    if (ttb != null) {
      metadataKey += ':ttb:$ttb';
    }
    if (ttr != null) {
      metadataKey += ':ttr:$ttr';
    }
    if (ccd != null) {
      metadataKey += ':ccd:$ccd';
    }
    if (isBinary != null) {
      metadataKey += ':isBinary:$isBinary';
    }
    if (isEncrypted != null) {
      metadataKey += ':isEncrypted:$isEncrypted';
    }
    if (sharedKeyEncrypted.isNotNull) {
      metadataKey += ':$SHARED_KEY_ENCRYPTED:$sharedKeyEncrypted';
    }
    if (pubKeyChecksum.isNotNull) {
      metadataKey += ':$SHARED_WITH_PUBLIC_KEY_CHECK_SUM:$pubKeyChecksum';
    }
    if (encoding.isNotNull) {
      metadataKey += ':$ENCODING:$encoding';
    }
    return metadataKey;
  }
}
