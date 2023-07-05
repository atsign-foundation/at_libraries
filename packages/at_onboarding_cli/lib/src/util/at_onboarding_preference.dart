import 'dart:core';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/util/registrar_api_constants.dart';

class AtOnboardingPreference extends AtClientPreference {
  /// specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;

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
  String registrarUrl = RegistrarApiConstants.apiHostProd;
}
