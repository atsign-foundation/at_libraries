import 'dart:typed_data';

import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_commons/at_commons.dart';
import 'package:crypto/crypto.dart';
import 'package:ecdsa/ecdsa.dart' as ecdsa;
import 'package:elliptic/elliptic.dart';

/// Data signing and verification for ECDSA - elliptic curve
class EccSigningAlgo implements AtSigningAlgorithm {
  SigningAlgoType? _signingAlgoType;
  HashingAlgoType? _hashingAlgoType;
  EccSigningAlgo();

  @override
  Uint8List sign(Uint8List dataHash) {
    throw UnimplementedError('not implemented');
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, {String? publicKey}) {
    if (publicKey == null) {
      throw AtException('public key not set not ecc verification');
    }
    var ec = getSecp256r1();
    var hashHex = sha256.convert(signedData).toString();
    var hash = List<int>.generate(hashHex.length ~/ 2,
        (i) => int.parse(hashHex.substring(i * 2, i * 2 + 2), radix: 16));
    var pubKey = ec.hexToPublicKey(publicKey);
    var eccSignature =
        ecdsa.Signature.fromCompactHex(String.fromCharCodes(signature));
    return ecdsa.verify(pubKey, hash, eccSignature);
  }

  @override
  HashingAlgoType? getHashingAlgo() => _hashingAlgoType;

  @override
  void setHashingAlgoType(HashingAlgoType? hashingAlgoType) {
    // TODO: implement setHashingAlgoType
  }

  @override
  SigningAlgoType? getSigningAlgo() => _signingAlgoType;

  @override
  void setSigningAlgoType(SigningAlgoType? signingAlgoType) {
    // TODO: implement setSigningAlgoType
  }
}
