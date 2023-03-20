import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/algorithm/aes_encryption_algo.dart';
import 'package:at_chops/src/algorithm/algo_type.dart';
import 'package:at_chops/src/algorithm/at_algorithm.dart';
import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/algorithm/default_encryption_algo.dart';
import 'package:at_chops/src/algorithm/default_signing_algo.dart';
import 'package:at_chops/src/algorithm/ecc_signing_algo.dart';
import 'package:at_chops/src/algorithm/pkam_signing_algo.dart';
import 'package:at_chops/src/at_chops_base.dart';
import 'package:at_chops/src/key/impl/aes_key.dart';
import 'package:at_chops/src/key/impl/at_chops_keys.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/key_type.dart';
import 'package:at_chops/src/metadata/at_signing_input.dart';
import 'package:at_chops/src/metadata/encryption_metadata.dart';
import 'package:at_chops/src/metadata/encryption_result.dart';
import 'package:at_chops/src/metadata/signing_metadata.dart';
import 'package:at_chops/src/metadata/signing_result.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_logger.dart';

class AtChopsImpl extends AtChops {
  AtChopsImpl(AtChopsKeys atChopsKeys) : super(atChopsKeys);

  final AtSignLogger _logger = AtSignLogger('AtChopsImpl');

  @override
  AtEncryptionResult decryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) {
    try {
      encryptionAlgorithm ??=
          _getEncryptionAlgorithm(encryptionKeyType, keyName)!;
      final atEncryptionMetaData = AtEncryptionMetaData(
          encryptionAlgorithm.runtimeType.toString(), encryptionKeyType);
      atEncryptionMetaData.keyName = keyName;
      final atEncryptionResult = AtEncryptionResult()
        ..atEncryptionMetaData = atEncryptionMetaData
        ..atEncryptionResultType = AtEncryptionResultType.bytes;
      if (encryptionAlgorithm is SymmetricEncryptionAlgorithm) {
        atEncryptionResult.result = encryptionAlgorithm.decrypt(data, iv: iv!);
        atEncryptionMetaData.iv = iv;
      } else {
        atEncryptionResult.result = encryptionAlgorithm.decrypt(data);
      }
      return atEncryptionResult;
    } on Exception catch (e) {
      throw AtDecryptionException(e.toString())
        ..stack(AtChainedException(
            Intent.decryptData,
            ExceptionScenario.decryptionFailed,
            'Failed to decrypt ${e.toString()}'));
    }
  }

  /// Decode the encrypted string to base64.
  /// Decode the encrypted byte to utf8 to support emoji chars.
  @override
  AtEncryptionResult decryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) {
    try {
      final decryptionResult = decryptBytes(
          base64Decode(data), encryptionKeyType,
          encryptionAlgorithm: encryptionAlgorithm, iv: iv);
      final atEncryptionResult = AtEncryptionResult()
        ..atEncryptionMetaData = decryptionResult.atEncryptionMetaData
        ..atEncryptionResultType = AtEncryptionResultType.string;
      atEncryptionResult.result = utf8.decode(decryptionResult.result);
      return atEncryptionResult;
    } on AtDecryptionException {
      rethrow;
    }
  }

  @override
  AtEncryptionResult encryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) {
    try {
      encryptionAlgorithm ??=
          _getEncryptionAlgorithm(encryptionKeyType, keyName)!;
      final atEncryptionMetaData = AtEncryptionMetaData(
          encryptionAlgorithm.runtimeType.toString(), encryptionKeyType);
      atEncryptionMetaData.keyName = keyName;
      final atEncryptionResult = AtEncryptionResult()
        ..atEncryptionMetaData = atEncryptionMetaData
        ..atEncryptionResultType = AtEncryptionResultType.bytes;
      if (encryptionAlgorithm is SymmetricEncryptionAlgorithm) {
        atEncryptionResult.result = encryptionAlgorithm.encrypt(data, iv: iv!);
        atEncryptionMetaData.iv = iv;
      } else {
        atEncryptionResult.result = encryptionAlgorithm.encrypt(data);
      }
      return atEncryptionResult;
    } on Exception catch (e) {
      throw AtEncryptionException(e.toString())
        ..stack(AtChainedException(
            Intent.decryptData,
            ExceptionScenario.decryptionFailed,
            'Failed to encrypt ${e.toString()}'));
    }
  }

  /// Encode the input string to utf8 to support emoji chars.
  /// Encode the encrypted bytes to base64.
  @override
  AtEncryptionResult encryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) {
    try {
      final utfEncodedData = utf8.encode(data);
      final encryptionResult = encryptBytes(
          Uint8List.fromList(utfEncodedData), encryptionKeyType,
          encryptionAlgorithm: encryptionAlgorithm, iv: iv);
      final atEncryptionResult = AtEncryptionResult()
        ..atEncryptionMetaData = encryptionResult.atEncryptionMetaData
        ..atEncryptionResultType = AtEncryptionResultType.string;
      atEncryptionResult.result = base64.encode(encryptionResult.result);
      return atEncryptionResult;
    } on AtEncryptionException {
      rethrow;
    }
  }

  @override
  String hash(Uint8List signedData, AtHashingAlgorithm hashingAlgorithm) {
    return hashingAlgorithm.hash(signedData);
  }

  @override
  // ignore: deprecated_member_use_from_same_package
  AtSigningResult signBytes(Uint8List data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getSigningAlgorithm(signingKeyType)!;

    // hard coding signing and hashing algo since this method is deprecated
    final atSigningMetadata = AtSigningMetaData(SigningAlgoType.rsa2048,
        HashingAlgoType.sha256, DateTime.now().toUtc());
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bytes;
    atSigningResult.result = signingAlgorithm.sign(data);
    return atSigningResult;
  }

  @override
  AtSigningResult verifySignatureBytes(
      Uint8List data,
      Uint8List signature,
      // ignore: deprecated_member_use_from_same_package
      SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getSigningAlgorithm(signingKeyType)!;
    // hard coding signing and hashing algo since this method is deprecated
    final atSigningMetadata = AtSigningMetaData(SigningAlgoType.rsa2048,
        HashingAlgoType.sha256, DateTime.now().toUtc());
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bool;
    atSigningResult.result = signingAlgorithm.verify(data, signature);
    return atSigningResult;
  }

  @override
  // ignore: deprecated_member_use_from_same_package
  AtSigningResult signString(String data, SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    final signingResult = signBytes(
        utf8.encode(data) as Uint8List, signingKeyType,
        signingAlgorithm: signingAlgorithm);
    final atSigningMetadata = signingResult.atSigningMetaData;
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.string;
    atSigningResult.result = base64Encode(signingResult.result);
    return atSigningResult;
  }

  @override
  AtSigningResult verifySignatureString(
      // ignore: deprecated_member_use_from_same_package
      String data,
      String signature,
      // ignore: deprecated_member_use_from_same_package
      SigningKeyType signingKeyType,
      {AtSigningAlgorithm? signingAlgorithm}) {
    final signingResult = verifySignatureBytes(
        utf8.encode(data) as Uint8List, base64Decode(signature), signingKeyType,
        signingAlgorithm: signingAlgorithm);
    final atSigningMetadata = signingResult.atSigningMetaData;
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bool;
    atSigningResult.result = signingResult.result;
    return atSigningResult;
  }

  @override
  AtSigningResult sign(AtSigningInput signingInput) {
    final dataBytes = _getBytes(signingInput.data);
    return _signBytes(dataBytes, signingInput,
        signingAlgorithm: signingInput.signingAlgorithm);
  }

  // change this method to public in the next major release and remove existing public method.
  AtSigningResult _signBytes(Uint8List data, AtSigningInput signingInput,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getSigningAlgorithmV2(signingInput)!;
    final atSigningMetadata = AtSigningMetaData(signingInput.signingAlgoType,
        signingInput.hashingAlgoType, DateTime.now().toUtc());
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bytes;
    try {
      atSigningResult.result = base64Encode(signingAlgorithm.sign(data));
    } on AtSigningException {
      rethrow;
    }
    return atSigningResult;
  }

  @override
  AtSigningResult verify(AtSigningVerificationInput verifyInput) {
    _logger.finer('Calling verify for input : $verifyInput ');
    final dataBytes = _getBytes(verifyInput.data);
    final signatureBytes = _getBytes(verifyInput.signature);
    return _verifySignatureBytes(dataBytes, signatureBytes, verifyInput);
  }

  AtSigningResult _verifySignatureBytes(Uint8List data, Uint8List signature,
      AtSigningVerificationInput verificationInput,
      {AtSigningAlgorithm? signingAlgorithm}) {
    signingAlgorithm ??= _getVerificationAlgorithm(verificationInput)!;
    _logger
        .finer('verification algo: ${signingAlgorithm.runtimeType.toString()}');
    final atSigningMetadata = AtSigningMetaData(
        verificationInput.signingAlgoType,
        verificationInput.hashingAlgoType,
        DateTime.now().toUtc());
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bool;
    try {
      atSigningResult.result = signingAlgorithm.verify(data, signature,
          publicKey: verificationInput.publicKey);
    } on AtSigningVerificationException {
      rethrow;
    }
    _logger.finer('verification result: ${atSigningResult.result}');
    return atSigningResult;
  }

  AtEncryptionAlgorithm? _getEncryptionAlgorithm(
      EncryptionKeyType encryptionKeyType, String? keyName) {
    switch (encryptionKeyType) {
      case EncryptionKeyType.rsa2048:
        return DefaultEncryptionAlgo(_getEncryptionKeyPair(keyName)!);
      case EncryptionKeyType.rsa4096:
        // TODO: Handle this case.
        break;
      case EncryptionKeyType.ecc:
        // TODO: Handle this case.
        break;
      case EncryptionKeyType.aes128:
        return AESEncryptionAlgo(atChopsKeys.symmetricKey! as AESKey);
      case EncryptionKeyType.aes256:
        return AESEncryptionAlgo(atChopsKeys.symmetricKey! as AESKey);
      default:
        throw AtEncryptionException(
            'Cannot find encryption algorithm for encryption key type $encryptionKeyType');
    }
    return null;
  }

  AtEncryptionKeyPair? _getEncryptionKeyPair(String? keyName) {
    if (keyName == null) {
      return atChopsKeys.atEncryptionKeyPair!;
    }
    // #TODO plugin implementation for different keyNames
    return null;
  }

  // ignore: deprecated_member_use_from_same_package
  AtSigningAlgorithm? _getSigningAlgorithm(SigningKeyType signingKeyType) {
    switch (signingKeyType) {
      // ignore: deprecated_member_use_from_same_package
      case SigningKeyType.pkamSha256:
        return PkamSigningAlgo(
            atChopsKeys.atPkamKeyPair!, HashingAlgoType.sha256);

      // ignore: deprecated_member_use_from_same_package
      case SigningKeyType.signingSha256:
        return DefaultSigningAlgo(
            atChopsKeys.atEncryptionKeyPair!, HashingAlgoType.sha256);
      default:
        throw AtSigningException(
            'Cannot find signing algorithm for signing key type $signingKeyType');
    }
  }

  AtSigningAlgorithm? _getSigningAlgorithmV2(AtSigningInput signingInput) {
    if (signingInput.signingAlgorithm != null) {
      return signingInput.signingAlgorithm;
    } else if (signingInput.signingMode != null &&
        signingInput.signingMode == AtSigningMode.pkam) {
      return PkamSigningAlgo(
          atChopsKeys.atPkamKeyPair!, signingInput.hashingAlgoType);
    } else if (signingInput.signingMode != null &&
        signingInput.signingMode == AtSigningMode.data) {
      return DefaultSigningAlgo(
          atChopsKeys.atEncryptionKeyPair!, signingInput.hashingAlgoType);
    } else {
      throw AtSigningException(
          'Cannot find signing algorithm for signing input  $signingInput');
    }
  }

  AtSigningAlgorithm? _getVerificationAlgorithm(
      AtSigningVerificationInput verificationInput) {
    if (verificationInput.signingAlgorithm != null) {
      return verificationInput.signingAlgorithm;
    }
    if (verificationInput.signingAlgoType == SigningAlgoType.ecc_secp256r1) {
      return EccSigningAlgo();
    } else if (verificationInput.signingMode != null &&
        verificationInput.signingMode == AtSigningMode.pkam) {
      if (atChopsKeys.atPkamKeyPair != null) {
        return PkamSigningAlgo(
            atChopsKeys.atPkamKeyPair, verificationInput.hashingAlgoType);
      } else {
        return PkamSigningAlgo(null, verificationInput.hashingAlgoType);
      }
    } else if (verificationInput.signingMode != null &&
        verificationInput.signingMode == AtSigningMode.data &&
        atChopsKeys.atEncryptionKeyPair != null) {
      return DefaultSigningAlgo(
          atChopsKeys.atEncryptionKeyPair, verificationInput.hashingAlgoType);
    } else {
      throw AtSigningVerificationException(
          'Cannot find signing algorithm for signing input  $verificationInput');
    }
  }

  Uint8List _getBytes(dynamic data) {
    if (data is String) {
      return utf8.encode(data) as Uint8List;
    } else if (data is Uint8List) {
      return data;
    } else {
      throw InvalidDataException('Unrecognized type of data: $data');
    }
  }

  @override
  String readPublicKey(String publicKeyId) {
    // This method is implemented only for extensions of AtChops that use secure element or any other source for private keys other than the default source(.atKeys file)
    throw UnimplementedError();
  }
}
