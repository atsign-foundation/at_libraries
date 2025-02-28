import 'dart:async';
import 'dart:typed_data';

import 'package:at_chops/src/signing/rsa_signing_algo.dart';

/// Interface for data signing. Data is signed using private key from a key pair
/// Signed data signature is verified with public key of the key pair.
abstract class AtSigningAlgorithm {
  /// Signs the data using private key of asymmetric key pair
  FutureOr<Uint8List> sign(Uint8List data);

  /// Verifies the data signature using public key of asymmetric key pair or the passed [publicKey]
  FutureOr<bool> verify(Uint8List signedData, Uint8List signature,
      {String? publicKey});
}

class DefaultSigningAlgo extends RSASigningAlgo {
  DefaultSigningAlgo(super.encryptionKeyPair, super.hashingAlgoType);
}

// ignore: constant_identifier_names
enum SigningAlgoType { ecc_secp256r1, rsa2048, rsa4096 }
