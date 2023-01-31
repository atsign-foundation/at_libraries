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

  /// See [Metadata.isBinary]
  bool? isBinary;

  /// See [Metadata.isEncrypted]
  bool? isEncrypted;

  String? operation;

  bool isJson = false;

  /// Indicates if the key is local
  /// If the key is local, the key does not sync between cloud and local secondary
  bool isLocal = false;



  /// See [Metadata.ttl]
  int? ttl;

  /// See [Metadata.ttb]
  int? ttb;

  /// See [Metadata.ttr]
  int? ttr;

  /// See [Metadata.ccd]
  bool? ccd;

  /// See [Metadata.dataSignature]
  String? dataSignature;

  /// See [Metadata.sharedKeyStatus]
  String? sharedKeyStatus;

  /// See [Metadata.sharedKeyEnc]
  String? sharedKeyEncrypted;

  /// checksum of the the public key of [sharedWith] atsign. Will be set only when [sharedWith] is set.
  /// See [Metadata.pubKeyCS]
  String? pubKeyChecksum;

  /// See [Metadata.encoding]
  String? encoding;

  /// See [Metadata.encKeyName]
  String? encKeyName;

  /// See [Metadata.encAlgo]
  String? encAlgo;

  /// See [Metadata.ivNonce]
  String? ivNonce;

  /// See [Metadata.skeEncKeyName]
  String? skeEncKeyName;

  /// See [Metadata.skeEncAlgo]
  String? skeEncAlgo;

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
      metadata.isPublic = isPublic;
      if (isEncrypted != null) {
        metadata.isEncrypted = isEncrypted!;
      }
      if (isBinary != null) {
        metadata.isBinary = isBinary!;
      }
      metadata.ttl = ttl;
      metadata.ttb = ttb;
      metadata.ttr = ttr;
      metadata.ccd = ccd;
      metadata.dataSignature = dataSignature;
      metadata.sharedKeyStatus = sharedKeyStatus;
      metadata.sharedKeyEnc = sharedKeyEncrypted;
      metadata.pubKeyCS = pubKeyChecksum;
      metadata.encoding = encoding;
      metadata.encKeyName = encKeyName;
      metadata.encAlgo = encAlgo;
      metadata.ivNonce = ivNonce;
      metadata.skeEncKeyName = skeEncKeyName;
      metadata.skeEncAlgo = skeEncAlgo;
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

  String buildKey() {
    if (atKeyObj.key != null) {
      return atKeyObj.toString();
    }
    super.atKeyObj
      ..key = atKey
      ..sharedWith = VerbUtil.formatAtSign(sharedWith)
      ..sharedBy = VerbUtil.formatAtSign(sharedBy)
      ..metadata = (Metadata()
        ..isPublic = isPublic
        ..isBinary = isBinary
        ..isEncrypted = isEncrypted
        ..ttl = ttl
        ..ttb = ttb
        ..ttr = ttr
        ..ccd = ccd
        ..dataSignature = dataSignature
        ..sharedKeyStatus = sharedKeyStatus
        ..sharedKeyEnc = sharedKeyEncrypted
        ..pubKeyCS = pubKeyChecksum
        ..encoding = encoding
        ..encKeyName = encKeyName
        ..encAlgo = encAlgo
        ..ivNonce = ivNonce
        ..skeEncKeyName = skeEncKeyName
        ..skeEncAlgo = skeEncAlgo
      )
      ..isLocal = isLocal;
    // If validation is successful, build the command and returns;
    // else throws exception.
    validateKey();
    return super.atKeyObj.toString();
  }

  String buildCommandForMeta() {
    var command = 'update:meta';
    command += ':${buildKey()}';
    command += buildMetadataString();
    command += '\n';
    return command;
  }

  static UpdateVerbBuilder? getBuilder(String command) {
    if (command != command.trim()) {
      throw IllegalArgumentException('Commands may not have leading or trailing whitespace');
    }
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

    builder.dataSignature = verbParams[PUBLIC_DATA_SIGNATURE];

    if (verbParams[IS_BINARY] != null) {
      builder.isBinary = _getBoolVerbParams(verbParams[IS_BINARY]!);
    }
    if (verbParams[IS_ENCRYPTED] != null) {
      builder.isEncrypted = _getBoolVerbParams(verbParams[IS_ENCRYPTED]!);
    }

    builder.sharedKeyEncrypted = verbParams[SHARED_KEY_ENCRYPTED];
    builder.pubKeyChecksum = verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM];
    builder.sharedKeyStatus = verbParams[SHARED_KEY_STATUS];
    builder.encoding = verbParams[ENCODING];
    builder.encKeyName = verbParams[ENCRYPTING_KEY_NAME];
    builder.encAlgo = verbParams[ENCRYPTING_ALGO];
    builder.ivNonce = verbParams[IV_OR_NONCE];
    builder.skeEncKeyName = verbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME];
    builder.skeEncAlgo = verbParams[SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO];

    builder.value = verbParams[VALUE];

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

  /// Builds the metadata part of the command.
  String buildMetadataString() {
    String metadataString = '';

    // NB The order of the verb parameters is important - it MUST match the order
    // in the regular expressions [VerbSyntax.update] and [VerbSyntax.update_meta]
    if (ttl != null) {
      metadataString += ':ttl:$ttl';
    }
    if (ttb != null) {
      metadataString += ':ttb:$ttb';
    }
    if (ttr != null) {
      metadataString += ':ttr:$ttr';
    }
    if (ccd != null) {
      metadataString += ':ccd:$ccd';
    }
    if (dataSignature.isNotNullOrEmpty) {
      metadataString += ':$PUBLIC_DATA_SIGNATURE:$dataSignature';
    }
    if (sharedKeyStatus.isNotNullOrEmpty) {
      metadataString += ':$SHARED_KEY_STATUS:$sharedKeyStatus';
    }
    if (isBinary != null) {
      metadataString += ':isBinary:$isBinary';
    }
    if (isEncrypted != null) {
      metadataString += ':isEncrypted:$isEncrypted';
    }
    if (sharedKeyEncrypted.isNotNullOrEmpty) {
      metadataString += ':$SHARED_KEY_ENCRYPTED:$sharedKeyEncrypted';
    }
    if (pubKeyChecksum.isNotNullOrEmpty) {
      metadataString += ':$SHARED_WITH_PUBLIC_KEY_CHECK_SUM:$pubKeyChecksum';
    }
    if (encoding.isNotNullOrEmpty) {
      metadataString += ':$ENCODING:$encoding';
    }
    if (encKeyName.isNotNullOrEmpty) {
      metadataString += ':$ENCRYPTING_KEY_NAME:$encKeyName';
    }
    if (encAlgo.isNotNullOrEmpty) {
      metadataString += ':$ENCRYPTING_ALGO:$encAlgo';
    }
    if (ivNonce.isNotNullOrEmpty) {
      metadataString += ':$IV_OR_NONCE:$ivNonce';
    }
    if (skeEncKeyName.isNotNullOrEmpty) {
      metadataString += ':$SHARED_KEY_ENCRYPTED_ENCRYPTING_KEY_NAME:$skeEncKeyName';
    }
    if (skeEncAlgo.isNotNullOrEmpty) {
      metadataString += ':$SHARED_KEY_ENCRYPTED_ENCRYPTING_ALGO:$skeEncAlgo';
    }
    return metadataString;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateVerbBuilder &&
          runtimeType == other.runtimeType &&
          atKey == other.atKey &&
          value == other.value &&
          sharedWith == other.sharedWith &&
          sharedBy == other.sharedBy &&
          isPublic == other.isPublic &&
          isBinary == other.isBinary &&
          isEncrypted == other.isEncrypted &&
          operation == other.operation &&
          isJson == other.isJson &&
          isLocal == other.isLocal &&
          ttl == other.ttl &&
          ttb == other.ttb &&
          ttr == other.ttr &&
          ccd == other.ccd &&
          dataSignature == other.dataSignature &&
          sharedKeyStatus == other.sharedKeyStatus &&
          sharedKeyEncrypted == other.sharedKeyEncrypted &&
          pubKeyChecksum == other.pubKeyChecksum &&
          encoding == other.encoding &&
          encKeyName == other.encKeyName &&
          encAlgo == other.encAlgo &&
          ivNonce == other.ivNonce &&
          skeEncKeyName == other.skeEncKeyName &&
          skeEncAlgo == other.skeEncAlgo;

  @override
  int get hashCode =>
      atKey.hashCode ^
      value.hashCode ^
      sharedWith.hashCode ^
      sharedBy.hashCode ^
      isPublic.hashCode ^
      isBinary.hashCode ^
      isEncrypted.hashCode ^
      operation.hashCode ^
      isJson.hashCode ^
      isLocal.hashCode ^
      ttl.hashCode ^
      ttb.hashCode ^
      ttr.hashCode ^
      ccd.hashCode ^
      dataSignature.hashCode ^
      sharedKeyStatus.hashCode ^
      sharedKeyEncrypted.hashCode ^
      pubKeyChecksum.hashCode ^
      encoding.hashCode ^
      encKeyName.hashCode ^
      encAlgo.hashCode ^
      ivNonce.hashCode ^
      skeEncKeyName.hashCode ^
      skeEncAlgo.hashCode;
}
