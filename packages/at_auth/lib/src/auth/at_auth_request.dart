import 'package:at_auth/src/keys/at_security_keys.dart';
import 'package:at_commons/at_commons.dart';

class AtAuthRequest {
  String atSign;
  AtAuthRequest(this.atSign);
  String? enrollmentId;
  AtSecurityKeys? atSecurityKeys;
  PkamAuthMode authMode = PkamAuthMode.keysFile;
  String? atKeysFilePath;

  /// public key id from secure element if [authMode] is [PkamAuthMode.sim]
  String? publicKeyId;
}
