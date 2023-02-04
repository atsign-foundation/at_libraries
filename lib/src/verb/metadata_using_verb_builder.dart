import 'package:meta/meta.dart';

import '../keystore/at_key.dart';
import 'abstract_verb_builder.dart';
import 'verb_util.dart';

abstract class MetadataUsingVerbBuilder extends AbstractVerbBuilder {
  MetadataUsingVerbBuilder() {
    atKeyObj.metadata!.isBinary = null;
  }

  /// See [AtKey.key]
  String? get atKey => atKeyObj.key;
  /// See [AtKey.key]
  set atKey (String? s) => atKeyObj.key = s;

  /// See [AtKey.sharedWith]
  String? get sharedWith => atKeyObj.sharedWith;
  /// See [AtKey.sharedWith]
  set sharedWith (String? s) => atKeyObj.sharedWith = VerbUtil.formatAtSign(s);

  /// See [AtKey.sharedBy]
  String? get sharedBy => atKeyObj.sharedBy;
  /// See [AtKey.sharedBy]
  set sharedBy (String? s) => atKeyObj.sharedBy = VerbUtil.formatAtSign(s);

  Metadata get metadata => atKeyObj.metadata!;

  /// See [Metadata.isPublic]
  bool get isPublic => metadata.isPublic!;
  /// See [Metadata.isPublic]
  set isPublic (bool b) => metadata.isPublic = b;

  /// See [Metadata.isBinary]
  bool? get isBinary => metadata.isBinary;
  /// See [Metadata.isBinary]
  set isBinary (bool? b) => metadata.isBinary = b;

  /// See [Metadata.isEncrypted]
  bool? get isEncrypted => metadata.isEncrypted;
  /// See [Metadata.isEncrypted]
  set isEncrypted (bool? b) => metadata.isEncrypted = b;
  /// See [Metadata.isEncrypted]
  bool? get isTextMessageEncrypted => metadata.isEncrypted;
  /// See [Metadata.isEncrypted]
  set isTextMessageEncrypted (bool? b) => metadata.isEncrypted = b;

  /// See [Metadata.ttl]
  int? get ttl => metadata.ttl;
  /// See [Metadata.ttl]
  set ttl (int? i) => metadata.ttl = i;

  /// See [Metadata.ttb]
  int? get ttb => metadata.ttb;
  /// See [Metadata.ttb]
  set ttb (int? i) => metadata.ttb = i;

  /// See [Metadata.ttr]
  int? get ttr => metadata.ttr;
  /// See [Metadata.ttr]
  set ttr (int? i) => metadata.ttr = i;

  /// See [Metadata.ccd]
  bool? get ccd => metadata.ccd;
  /// See [Metadata.ccd]
  set ccd (bool? b) => metadata.ccd = b;

  /// See [Metadata.dataSignature]
  String? get dataSignature => metadata.dataSignature;
  /// See [Metadata.dataSignature]
  set dataSignature (String? s) => metadata.dataSignature = s;

  /// See [Metadata.sharedKeyStatus]
  String? get sharedKeyStatus => metadata.sharedKeyStatus;
  /// See [Metadata.sharedKeyStatus]
  set sharedKeyStatus (String? s) => metadata.sharedKeyStatus = s;

  /// See [Metadata.sharedKeyEnc]
  String? get sharedKeyEncrypted => metadata.sharedKeyEnc;
  /// See [Metadata.sharedKeyEnc]
  set sharedKeyEncrypted (String? s) => metadata.sharedKeyEnc = s;

  /// See [Metadata.pubKeyCS]
  String? get pubKeyChecksum => metadata.pubKeyCS;
  /// See [Metadata.pubKeyCS]
  set pubKeyChecksum (String? s) => metadata.pubKeyCS = s;

  /// See [Metadata.encoding]
  String? get encoding => metadata.encoding;
  /// See [Metadata.encoding]
  set encoding (String? s) => metadata.encoding = s;

  /// See [Metadata.encKeyName]
  String? get encKeyName => metadata.encKeyName;
  /// See [Metadata.encKeyName]
  set encKeyName (String? s) => metadata.encKeyName = s;

  /// See [Metadata.encAlgo]
  String? get encAlgo => metadata.encAlgo;
  /// See [Metadata.encAlgo]
  set encAlgo (String? s) => metadata.encAlgo = s;

  /// See [Metadata.ivNonce]
  String? get ivNonce => metadata.ivNonce;
  /// See [Metadata.ivNonce]
  set ivNonce (String? s) => metadata.ivNonce = s;

  /// See [Metadata.skeEncKeyName]
  String? get skeEncKeyName => metadata.skeEncKeyName;
  /// See [Metadata.skeEncKeyName]
  set skeEncKeyName (String? s) => metadata.skeEncKeyName = s;

  /// See [Metadata.skeEncAlgo]
  String? get skeEncAlgo => metadata.skeEncAlgo;
  /// See [Metadata.skeEncAlgo]
  set skeEncAlgo (String? s) => metadata.skeEncAlgo = s;
}