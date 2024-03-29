import 'package:at_commons/at_commons.dart';

class AtOnboardingRequest {
  String atSign;
  AtOnboardingRequest(this.atSign);
  PkamAuthMode authMode = PkamAuthMode.keysFile;
  bool enableEnrollment = false;
  String rootDomain = 'root.atsign.org';
  int rootPort = 64;
  String? appName;
  String? deviceName;

  /// public key id if [authMode] is [PkamAuthMode.sim]
  String? publicKeyId;
}
