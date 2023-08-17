import 'dart:core';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/util/registrar_api_constants.dart';

class AtOnboardingPreference extends AtClientPreference {
  /// specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;

  /// specify path of qr code containing cram secret
  @Deprecated('qr_code based cram authentication not supported anymore')
  String? qrCodePath;

  /// signing algorithm to use for pkam authentication
  SigningAlgoType signingAlgoType = SigningAlgoType.rsa2048;

  /// hashing algorithm to use for pkam authentication
  HashingAlgoType hashingAlgoType = HashingAlgoType.sha256;

  PkamAuthMode authMode = PkamAuthMode.keysFile;

  /// if [authMode] is sim, specify publicKeyId to be read from sim
  String? publicKeyId;

  bool skipSync = false;

  /// the hostName of the registrar which will be used to activate the atsign
  String registrarUrl = RegistrarApiConstants.apiHostProd;

  late String appName;

  late String deviceName;

  int apkamAuthRetryDurationMins = 30;
}
