import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';

// Input for data signing
class AtSigningInput {
  dynamic _data;

  HashingAlgoType? hashingAlgoType;

  SigningAlgoType? signingAlgoType;

  AtSigningAlgorithm? signingAlgorithm;

  AtSigningMode? signingMode;

  AtSigningInput(this._data);

  dynamic get data => _data;

  //#TODO implement toString
}

// Input for data signature verification
class AtSigningVerificationInput {
  dynamic _data;

  dynamic _signature;

  String _publicKey;

  HashingAlgoType? hashingAlgoType;

  SigningAlgoType? signingAlgoType;

  AtSigningMode? signingMode;

  AtSigningAlgorithm? signingAlgorithm;

  AtSigningVerificationInput(this._data, this._signature, this._publicKey);

  dynamic get data => _data;

  dynamic get signature => _signature;

  String get publicKey => _publicKey;

  //#TODO implement toString
}

enum AtSigningMode { pkam, data, sim }
