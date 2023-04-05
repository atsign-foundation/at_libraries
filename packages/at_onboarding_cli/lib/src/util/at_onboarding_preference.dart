import 'dart:core';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';

class AtOnboardingPreference extends AtClientPreference {
  //specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;

  //specify path of qr code containing cram secret
  String? qrCodePath;

  //signing algorithm to use for pkam authentication
  SigningAlgoType signingAlgoType = SigningAlgoType.rsa2048;

  //hashing algorithm to use for pkam authentication
  HashingAlgoType hashingAlgoType = HashingAlgoType.sha256;

  PkamAuthMode authMode = PkamAuthMode.keysFile;

  // if [authMode] is sim, specify publicKeyId to be read from sim
  String? publicKeyId;

  bool skipSync = false;
}

// If pkam auth mode is keysFile then pkam private key will be generated during onboarding and saved in the keys file.
// For subsequent authentication, pkam private key will be read from the keys file supplied by the user.
// If pkam auth mode is sim or any other secure element, then private key is not accessible directly. Only the data will be passed to the sim/secure element, pkam signature can be retrieved and verified.pkam private key will not be a part of keys file in this case.
enum PkamAuthMode { keysFile, sim }
