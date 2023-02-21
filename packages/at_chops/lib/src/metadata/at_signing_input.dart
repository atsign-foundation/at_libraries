import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/ecc_signing_algo.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';

/// Input to generate data signature
///
/// [_data] field is required for successful
/// generation of data signature
///
/// Algorithm used to sign/verify the data can be chosen
/// using [hashingAlgoType] and [signingAlgoType]
///
/// Defaults are [HashingAlgoType.sha256] and [SigningAlgoType.rsa2048]
///
/// Please Use the same [HashingAlgoType] and [SigningAlgoType] used to generate
/// the data signature
///
/// Please refer to the docs belonging to individual data fields
/// to be able to generate a valid instance
class AtSigningInput {
  /// Data that needs to be signed
  ///
  /// Data either needs to be of type [String] or [Uint8List]
  ///
  /// AtException will be thrown if data is of any other type
  dynamic _data;

  /// Choose [HashingAlgoType] from [HashingAlgoType.values]
  ///
  /// Default [HashingAlgoType] will be [HashingAlgoType.sha256]
  HashingAlgoType? hashingAlgoType;

  /// Choose [SigningAlgoType] from [SigningAlgoType.values]
  ///
  /// Default [SigningAlgoType] will be [SigningAlgoType.rsa2048]
  SigningAlgoType? signingAlgoType;

  /// SigningAlgorithm that will be used to sign/verify data
  ///
  /// Available options are [DefaultSigningAlgo], [PkamSigningAlgo], [EccSigningAlgo]
  AtSigningAlgorithm? signingAlgorithm;

  /// Select signingMode from [AtSigningMode]
  ///
  /// Use [AtSigningMode.data] for a general purpose signing
  ///
  /// Use [AtSigningMode.pkam] when signing pkam challenges
  AtSigningMode? signingMode;

  AtSigningInput(this._data);

  dynamic get data => _data;

//#TODO implement toString
}

/// Input for data signature verification
///
/// [_data], [_signature] and [_publicKey] fields are required for successful
/// verification of data signature
///
/// Algorithm used to sign/verify the data can be chosen
/// using [hashingAlgoType] and [signingAlgoType]
///
/// Defaults are [HashingAlgoType.sha256] and [SigningAlgoType.rsa2048]
///
/// Please Use the same [HashingAlgoType] and [SigningAlgoType] used to generate
/// the data signature
///
/// Please refer to the docs belonging to individual data fields
/// to be able to generate a valid instance
class AtSigningVerificationInput {
  /// Data that has to verified
  ///
  /// Data needs to be either of type base64encoded [String] or [Uint8List]
  ///
  /// AtException will be thrown if data is of any other type
  dynamic _data;

  /// Signature of [_data] that will be used to verify
  ///
  /// Signature needs to be either of type base64encoded [String] or [Uint8List]
  ///
  /// AtException will be thrown if signature is of any other type
  dynamic _signature;

  /// Mandatory input
  ///
  /// PublicKey belonging to the AsymmetricKeypair that was used to sign [_signature]
  String _publicKey;

  /// Choose [HashingAlgoType] from [HashingAlgoType.values]
  ///
  /// Default [HashingAlgoType] will be [HashingAlgoType.sha256]
  HashingAlgoType? hashingAlgoType;

  /// Choose [SigningAlgoType] from [SigningAlgoType.values]
  /// Default [SigningAlgoType] will be [SigningAlgoType.rsa2048]
  SigningAlgoType? signingAlgoType;

  /// Select signingMode from [AtSigningMode]
  ///
  /// Use [AtSigningMode.data] for a general purpose signing
  ///
  /// Use [AtSigningMode.pkam] when signing pkam challenges
  AtSigningMode? signingMode;

  /// SigningAlgorithm that will be used to sign/verify data
  ///
  /// Available options are [DefaultSigningAlgo], [PkamSigningAlgo], [EccSigningAlgo]
  AtSigningAlgorithm? signingAlgorithm;

  AtSigningVerificationInput(this._data, this._signature, this._publicKey);

  dynamic get data => _data;

  dynamic get signature => _signature;

  String get publicKey => _publicKey;

//#TODO implement toString
}

enum AtSigningMode { pkam, data, sim }
