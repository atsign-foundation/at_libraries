import 'package:at_commons/at_commons.dart';

class AtOnboardingRequest {
  String atSign;
  AtOnboardingRequest(this.atSign);
  PkamAuthMode authMode = PkamAuthMode.keysFile;
  bool enableEnrollment = false;
  late String rootDomain;
  late int rootPort;
  String? appName;
  String? deviceName;

  /// public key id if [authMode] is [PkamAuthMode.sim]
  String? publicKeyId;
}
