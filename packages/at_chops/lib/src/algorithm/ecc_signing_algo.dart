import 'dart:typed_data';

import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypto/crypto.dart';
import 'package:ecdsa/ecdsa.dart' as ecdsa;
import 'package:elliptic/elliptic.dart' as elliptic;

/// Data signing and verification for ECDSA - elliptic curve
/// Currently uses sha256 hashing for data. #TODO implement using _hashingAlgoType in the future.
class EccSigningAlgo implements AtSigningAlgorithm {
  SigningAlgoType? _signingAlgoType;
  HashingAlgoType? _hashingAlgoType;
  elliptic.PrivateKey? _privateKey;

  EccSigningAlgo();

  @override
  Uint8List sign(Uint8List data) {
    if (_privateKey == null) {
      throw AtException(
          'elliptic private key has to be set for signing operation');
    }
    var hashHex = sha256.convert(data).toString();
    var hash = List<int>.generate(hashHex.length ~/ 2,
        (i) => int.parse(hashHex.substring(i * 2, i * 2 + 2), radix: 16));
    return Uint8List.fromList(
        ecdsa.signature(_privateKey!, hash).toCompactHex().codeUnits);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, {String? publicKey}) {
    if (publicKey == null && _privateKey == null) {
      throw AtException('public key not set not ecc verification');
    }
    var ec = elliptic.getSecp256r1();
    var hashHex = sha256.convert(signedData).toString();
    var hash = List<int>.generate(hashHex.length ~/ 2,
        (i) => int.parse(hashHex.substring(i * 2, i * 2 + 2), radix: 16));
    var pubKey;
    if (publicKey != null) {
      pubKey = ec.hexToPublicKey(publicKey);
    } else {
      pubKey = _privateKey!.publicKey;
    }
    var eccSignature =
        ecdsa.Signature.fromCompactHex(String.fromCharCodes(signature));
    return ecdsa.verify(pubKey, hash, eccSignature);
  }

  @override
  HashingAlgoType? getHashingAlgo() => _hashingAlgoType;

  @override
  void setHashingAlgoType(HashingAlgoType? hashingAlgoType) {
    _hashingAlgoType = hashingAlgoType;
  }

  @override
  SigningAlgoType? getSigningAlgo() => _signingAlgoType;

  @override
  void setSigningAlgoType(SigningAlgoType? signingAlgoType) {
    _signingAlgoType = signingAlgoType;
  }

  elliptic.PrivateKey? get privateKey => _privateKey;

  set privateKey(elliptic.PrivateKey? value) {
    _privateKey = value;
  }
}
