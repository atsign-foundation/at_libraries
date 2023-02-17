import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_commons/at_commons.dart';

///Bean type class to be used for passing data_signing related input information
class AtSigningInput {
  ///data as String that is to be signed
  dynamic plainText;

  ///Expected length of the digest [use 256 (or) 512]
  ///256 will use SHA-256 for signing
  ///512 will use SHA-512 for signing
  int digestLength;

  ///used while verification
  ///Digest that needs to be verified
  String? digest;

  ///PublicKey used to verify digest
  String? verificationPublicKey;

  SigningKeyType signingKeyType;

  AtSigningAlgorithm? signingAlgorithm;

  AtSigningInput(this.plainText, this.signingKeyType, InputType inputType,
      {this.digest, this.signingAlgorithm, this.digestLength = 256}) {
    if (inputType == InputType.verificationInput && digest == null) {
      throw AtException('Digest required for verification');
    }
  }
}

enum InputType { signingInput, verificationInput }
