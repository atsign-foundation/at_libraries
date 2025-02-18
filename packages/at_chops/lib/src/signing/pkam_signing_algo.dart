import 'package:at_chops/src/signing/rsa_signing_algo.dart';

/// Data signing and verification for Public Key Authentication Mechanism - Pkam
class PkamSigningAlgo extends RSASigningAlgo {
  @override
  String get errorMessageKeyname => "Pkam";
  PkamSigningAlgo(super.encryptionKeyPair, super.hashingAlgoType);
}
