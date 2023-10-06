import 'package:at_auth/src/keys/at_auth_keys.dart';
import 'package:at_commons/at_commons.dart';

class AtAuthRequest {
  String atSign;
  AtAuthRequest(this.atSign, this.rootDomain, this.rootPort);
  String? enrollmentId;
  AtAuthKeys? atAuthKeys;
  String rootDomain;
  int rootPort;
  PkamAuthMode authMode = PkamAuthMode.keysFile;
  String? atKeysFilePath;

  /// public key id from secure element if [authMode] is [PkamAuthMode.sim]
  String? publicKeyId;
}
