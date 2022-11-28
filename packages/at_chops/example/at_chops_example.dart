import 'package:at_chops/at_chops.dart';

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
  final encryptedString =
      atChops.encryptString(data, EncryptionKeyType.rsa2048);
  //1.2 decrypt the data using [atEncryptionKeyPair.privateKey]
  final decryptedString =
      atChops.decryptString(encryptedString, EncryptionKeyType.rsa2048);
  assert(data == decryptedString, true);

  // 2 - Signing and data verification using asymmetric key pair
  final digest = 'sample pkam digest';
  //2.1 sign the digest using [atPkamKeyPair.privateKey]
  final signature = atChops.signString(digest, SigningKeyType.signingSha256);
  //2.2 verify the signature using [atPkamKeyPair.publicKey]
  final result = atChops.verifySignatureString(
      digest, signature, SigningKeyType.signingSha256);
  assert(result, true);
}
