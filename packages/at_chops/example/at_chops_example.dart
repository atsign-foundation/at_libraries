import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';

void main() {
  final atEncryptionKeyPair = AtChopsUtil
      .generateAtEncryptionKeyPair(); //use AtEncryptionKeyPair.create for using your own encryption key pair
  final atPkamKeyPair = AtChopsUtil
      .generateAtPkamKeyPair(); // use AtPkamKeyPair.create for using your own signing key pair
  // create AtChopsKeys instance using encryption and pkam key pair
  final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
  // create an instance of AtChopsImpl
  final atChops = AtChopsImpl(atChopsKeys);

  // 1 - Encryption and decryption using asymmetric key pair
  final data = 'Hello World';
  //1.1 encrypt the data using [atEncryptionKeyPair.publicKey]
  final encryptionResult =
      atChops.encryptString(data, EncryptionKeyType.rsa2048);

  //1.2 decrypt the data using [atEncryptionKeyPair.privateKey]
  final decryptionResult =
      atChops.decryptString(encryptionResult.result, EncryptionKeyType.rsa2048);
  assert(data == decryptionResult.result, true);

  // 2 - Signing and data verification using asymmetric key pair
  // Using signString() and verifyString()
  final digest = 'sample pkam digest';
  //2.1 sign the digest using [atPkamKeyPair.privateKey]
  final signingResult =
      atChops.signString(digest, SigningKeyType.signingSha256);

  //2.2 verify the signature using [atPkamKeyPair.publicKey]
  final verificationResult = atChops.verifySignatureString(
      digest, signingResult.result, SigningKeyType.signingSha256);
  assert(verificationResult.result, true);

  // 3 - Signing and data verification using asymmetric key pair
  // Using sign() and verify()
  String plainText = 'some demo data';
  //3.1.1 Create a valid instance of AtSigningInput
  AtSigningInput signingInput = AtSigningInput(plainText);
  AtSigningAlgorithm signingAlgorithm = DefaultSigningAlgo(
      atEncryptionKeyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha512);
  signingInput.signingAlgorithm = signingAlgorithm;
  //3.1.2 Use the instance of AtSigningInput to generate a signature
  final signResult = atChops.sign(signingInput);

  //3.2.1 Create a valid instance of AtSigningVerificationInput
  AtSigningVerificationInput? verificationInput = AtSigningVerificationInput(
      plainText, signResult.result, atEncryptionKeyPair.atPublicKey.publicKey);
  AtSigningAlgorithm verifyAlgorithm = DefaultSigningAlgo(
      atEncryptionKeyPair, SigningAlgoType.rsa2048, HashingAlgoType.sha512);
  verificationInput.signingAlgorithm = verifyAlgorithm;
  //3.2.2 Use the instance of AtSigningVerificationInput to verify the signature
  AtSigningResult verifyResult = atChops.verify(verificationInput);
  assert(verifyResult.result == true);
}
