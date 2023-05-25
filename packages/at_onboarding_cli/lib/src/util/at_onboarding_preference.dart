import 'dart:core';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';

class AtOnboardingPreference extends AtClientPreference {
  //specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;

  //specify path of qr code containing cram secret
  String? qrCodePath;

  //signing algorithm to use for pkam authentication
  @override
  SigningAlgoType signingAlgoType = SigningAlgoType.rsa2048;

  //hashing algorithm to use for pkam authentication
  @override
  HashingAlgoType hashingAlgoType = HashingAlgoType.sha256;

  PkamAuthMode authMode = PkamAuthMode.keysFile;

  // if [authMode] is sim, specify publicKeyId to be read from sim
  String? publicKeyId;

  bool skipSync = false;
}
