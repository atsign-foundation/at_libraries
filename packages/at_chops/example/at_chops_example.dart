import 'dart:io';
import 'dart:convert';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';

void main(List<String> args) async {
  AtChops atChops;
  if (args.isNotEmpty) {
    var atKeysFilePath = args[0];
    if (!File(atKeysFilePath).existsSync()) {
      throw Exception('\n Unable to find .atKeys file : $atKeysFilePath');
    }
    String atAuthData = await File(atKeysFilePath).readAsString();
    Map<String, String> atKeysDataMap = <String, String>{};
    json.decode(atAuthData).forEach((String key, dynamic value) {
      atKeysDataMap[key] = value.toString();
    });
    atChops = _createAtChops(atKeysDataMap);
  } else {
    final atEncryptionKeyPair = AtChopsUtil
        .generateAtEncryptionKeyPair(); //use AtEncryptionKeyPair.create for using your own encryption key pair
    final atPkamKeyPair = AtChopsUtil
        .generateAtPkamKeyPair(); // use AtPkamKeyPair.create for using your own signing key pair
    // create AtChopsKeys instance using encryption and pkam key pair
    final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
    // create an instance of AtChopsImpl
    atChops = AtChopsImpl(atChopsKeys);
  }

  var atEncryptionKeyPair = atChops.atChopsKeys.atEncryptionKeyPair;
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
      // ignore: deprecated_member_use_from_same_package
      atChops.signString(digest, SigningKeyType.signingSha256);

  //2.2 verify the signature using [atPkamKeyPair.publicKey]
  final verificationResult = atChops.verifySignatureString(
      // ignore: deprecated_member_use_from_same_package
      digest,
      signingResult.result,
      SigningKeyType.signingSha256);
  assert(verificationResult.result, true);

  // 3 - Signing and data verification using asymmetric key pair
  // Using sign() and verify()
  String plainText = 'some demo data';
  //3.1.1 Create a valid instance of AtSigningInput
  AtSigningInput signingInput = AtSigningInput(plainText);
  AtSigningAlgorithm signingAlgorithm =
      DefaultSigningAlgo(atEncryptionKeyPair, HashingAlgoType.sha512);
  signingInput.signingAlgorithm = signingAlgorithm;
  //3.1.2 Use the instance of AtSigningInput to generate a signature
  final signResult = atChops.sign(signingInput);

  //3.2.1 Create a valid instance of AtSigningVerificationInput
  AtSigningVerificationInput? verificationInput = AtSigningVerificationInput(
      plainText, signResult.result, atEncryptionKeyPair!.atPublicKey.publicKey);
  AtSigningAlgorithm verifyAlgorithm =
      DefaultSigningAlgo(atEncryptionKeyPair, HashingAlgoType.sha512);
  verificationInput.signingAlgorithm = verifyAlgorithm;
  //3.2.2 Use the instance of AtSigningVerificationInput to verify the signature
  AtSigningResult verifyResult = atChops.verify(verificationInput);
  assert(verifyResult.result == true);
}

AtChops _createAtChops(Map<String, String> atKeysDataMap) {
  final atEncryptionKeyPair = AtEncryptionKeyPair.create(
      atKeysDataMap[AuthKeyType.encryptionPublicKey]!,
      atKeysDataMap[AuthKeyType.encryptionPrivateKey]!);
  final atPkamKeyPair = AtPkamKeyPair.create(
      atKeysDataMap[AuthKeyType.pkamPublicKey]!,
      atKeysDataMap[AuthKeyType.pkamPrivateKey]!);
  final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
  return AtChopsImpl(atChopsKeys);
}

class AuthKeyType {
  static const String pkamPublicKey = 'aesPkamPublicKey';
  static const String pkamPrivateKey = 'aesPkamPrivateKey';
  static const String encryptionPublicKey = 'aesEncryptPublicKey';
  static const String encryptionPrivateKey = 'aesEncryptPrivateKey';
  static const String selfEncryptionKey = 'selfEncryptionKey';
}
