import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/aes_encryption_algo.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';
import 'package:at_chops/src/algorithm/rsa_encryption_algo.dart';
import 'package:at_chops/src/at_chops_base.dart';
import 'package:at_chops/src/key/impl/aes_key.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/key_type.dart';

class AtChopsImpl extends AtChops {
  AtChopsImpl(AtChopsKeys atChopsKeys) : super(atChopsKeys);

  @override
  Uint8List decryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm}) {
    encryptionAlgorithm ??= _getEncryptionAlgorithm(encryptionKeyType)!;
    return encryptionAlgorithm.decrypt(data);
  }

  /// Decode the encrypted string to base64.
  /// Decode the encrypted byte to utf8 to support emoji chars.
  @override
  String decryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm}) {
    final decryptedBytes = decryptBytes(base64Decode(data), encryptionKeyType,
        encryptionAlgorithm: encryptionAlgorithm);
    return utf8.decode(decryptedBytes);
  }

  @override
  Uint8List encryptBytes(Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm}) {
    encryptionAlgorithm ??= _getEncryptionAlgorithm(encryptionKeyType)!;
    return encryptionAlgorithm.encrypt(data);
  }

  /// Encode the input string to utf8 to support emoji chars.
  /// Encode the encrypted bytes to base64.
  @override
  String encryptString(String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm}) {
    final utfEncodedData = utf8.encode(data);
    final encryptedBytes = encryptBytes(
        Uint8List.fromList(utfEncodedData), encryptionKeyType,
        encryptionAlgorithm: encryptionAlgorithm);
    return base64.encode(encryptedBytes);
  }

  @override
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm) {
    return hashingAlgorithm.hash(signedData);
  }

  @override
  Uint8List signBytes(Uint8List data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getSigningAlgorithm(signingKeyType)!;
    return signingAlgorithm.sign(data);
  }

  @override
  bool verifySignatureBytes(
      Uint8List data, Uint8List signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getSigningAlgorithm(signingKeyType)!;
    return signingAlgorithm.verify(data, signature);
  }

  AtEncryptionAlgorithm? _getEncryptionAlgorithm(
      EncryptionKeyType encryptionKeyType) {
    switch (encryptionKeyType) {
      case EncryptionKeyType.rsa_2048:
        return RSAEncryptionAlgo(
            atChopsKeys.atEncryptionKeyPair!, encryptionKeyType);
      case EncryptionKeyType.rsa_4096:
        // TODO: Handle this case.
        break;
      case EncryptionKeyType.ecc:
        // TODO: Handle this case.
        break;
      case EncryptionKeyType.aes_128:
        // TODO: Handle this case.
        break;
      case EncryptionKeyType.aes_256:
        return AESEncryptionAlgo(atChopsKeys.symmetricKey! as AESKey);
      default:
        throw Exception(
            'Cannot find encryption algorithm for encryption key type $encryptionKeyType');
    }
  }

  AtSigningAlgorithm? _getSigningAlgorithm(SigningKeyType signingKeyType) {
    switch (signingKeyType) {
      case SigningKeyType.pkam_sha_256:
        return PkamSigningAlgo(atChopsKeys.atPkamKeyPair!, signingKeyType);
      case SigningKeyType.signing_sha_256:
        // TODO: Handle this case.
        break;
      default:
        throw Exception(
            'Cannot find signing algorithm for signing key type $signingKeyType');
    }
  }

  @override
  String signString(String data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    final signedBytes = signBytes(
        utf8.encode(data) as Uint8List, signingKeyType,
        signingAlgorithm: signingAlgorithm);
    return base64Encode(signedBytes);
  }

  @override
  bool verifySignatureString(
      String data, String signature, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    return verifySignatureBytes(
        utf8.encode(data) as Uint8List, base64Decode(signature), signingKeyType,
        signingAlgorithm: signingAlgorithm);
  }
}
