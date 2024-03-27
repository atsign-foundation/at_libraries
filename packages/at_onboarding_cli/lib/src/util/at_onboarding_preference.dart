import 'dart:core';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_register/at_register.dart';

class AtOnboardingPreference extends AtClientPreference {
  /// specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;

  /// specify path of qr code containing cram secret
  @Deprecated('qr_code based cram authentication not supported anymore')
  String? qrCodePath;

  /// signing algorithm to use for pkam authentication
  @override
  SigningAlgoType signingAlgoType = SigningAlgoType.rsa2048;

  /// hashing algorithm to use for pkam authentication
  @override
  HashingAlgoType hashingAlgoType = HashingAlgoType.sha256;

  PkamAuthMode authMode = PkamAuthMode.keysFile;

  /// if [authMode] is sim, specify publicKeyId to be read from sim
  String? publicKeyId;

  bool skipSync = false;

  /// the hostName of the registrar which will be used to activate the atsign
  String registrarUrl = RegistrarConstants.apiHostProd;

  String? appName;

  String? deviceName;

  int apkamAuthRetryDurationMins = 30;

  /// This enables apkamEnabledAuthentication. Creates default enrollmentId with
  /// super user access.
  ///
  /// Disabled by default. Set to true to enable
  bool enableEnrollmentDuringOnboard = false;
}
