// ignore_for_file: unnecessary_cast

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/at_chops.dart';
import 'package:at_chops/src/key/at_rsa_key_pair.dart';
import 'package:at_chops/types.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_utils/at_logger.dart';

class AtChopsImpl extends AtChops {
  @override
  final AtChopsKeys atChopsKeys;
  AtChopsImpl(this.atChopsKeys) : super.init();

  final AtSignLogger _logger = AtSignLogger('AtChopsImpl');

  @override
  FutureOr<AtEncryptionResult> decryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) async {
    try {
      encryptionAlgorithm ??=
          _getEncryptionAlgorithm(encryptionKeyType, keyName)!;
      if (encryptionAlgorithm is SymmetricEncryptionAlgorithm && iv == null) {
        throw AtDecryptionException(
            'Initialization vector required for decryption using SymmetricKey');
      }
      final atEncryptionMetaData = AtEncryptionMetaData(
          encryptionAlgorithm.runtimeType.toString(), encryptionKeyType);
      atEncryptionMetaData.keyName = keyName;
      final atEncryptionResult = AtEncryptionResult()
        ..atEncryptionMetaData = atEncryptionMetaData
        ..atEncryptionResultType = AtEncryptionResultType.bytes;
      if (encryptionAlgorithm is SymmetricEncryptionAlgorithm) {
        atEncryptionResult.result =
            await encryptionAlgorithm.decrypt(data, iv: iv!);
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
  FutureOr<AtEncryptionResult> decryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) async {
    try {
      final decryptionResult = await decryptBytes(
          base64Decode(data), encryptionKeyType,
          encryptionAlgorithm: encryptionAlgorithm, keyName: keyName, iv: iv);
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
  FutureOr<AtEncryptionResult> encryptBytes(
      Uint8List data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) async {
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
        atEncryptionResult.result =
            await encryptionAlgorithm.encrypt(data, iv: iv!);
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
  FutureOr<AtEncryptionResult> encryptString(
      String data, EncryptionKeyType encryptionKeyType,
      {AtEncryptionAlgorithm? encryptionAlgorithm,
      String? keyName,
      InitialisationVector? iv}) async {
    try {
      final utfEncodedData = utf8.encode(data);
      final encryptionResult = await encryptBytes(
          Uint8List.fromList(utfEncodedData), encryptionKeyType,
          keyName: keyName, encryptionAlgorithm: encryptionAlgorithm, iv: iv);
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
    if (hashingAlgorithm.runtimeType == DefaultHashingAlgo) {
      return DefaultHashingAlgo().hash(signedData);
    }
    throw AtException('$hashingAlgorithm is not supported');
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
    signingAlgorithm ??= _getSigningAlgorithm(signingInput)!;
    final atSigningMetadata = AtSigningMetaData(signingInput.signingAlgoType,
        signingInput.hashingAlgoType, DateTime.now().toUtc());
    final atSigningResult = AtSigningResult()
      ..atSigningMetaData = atSigningMetadata
      ..atSigningResultType = AtSigningResultType.bytes;
    try {
      atSigningResult.result =
          base64Encode(signingAlgorithm.sign(data) as List<int>);
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
      case EncryptionKeyType.rsa4096:
        return RsaEncryptionAlgo.fromKeyPair(
            _getEncryptionKeyPair(keyName) as AtRSAKeyPair);
      case EncryptionKeyType.ed25519:
        throw AtEncryptionException('EncryptionKeyType.ed25519 not supported');
      case EncryptionKeyType.aes128:
        return AESEncryptionAlgo(_getSymmetricKey(keyName)! as AtAESKey);
      case EncryptionKeyType.aes256:
        return AESEncryptionAlgo(_getSymmetricKey(keyName)! as AtAESKey);
      default:
        throw AtEncryptionException(
            'Cannot find encryption algorithm for encryption key type $encryptionKeyType');
    }
  }

  AsymmetricKeyPair? _getEncryptionKeyPair(String? keyName) {
    if (keyName == null) {
      return atChopsKeys.atEncryptionKeyPair!;
    }
    // #TODO For now return atEncryptionKeyPair which can be rsa2048 or rsa4096.
    // #TODO  When we remove atChopsKeys from AtChopsImpl constructor, plugin implementation for different keyNames
    return null;
  }

  SymmetricKey? _getSymmetricKey(String? keyName) {
    if (keyName == null || keyName == StandardAtKeysNames.selfEncryptionKey) {
      return atChopsKeys.selfEncryptionKey!;
    } else if (keyName == StandardAtKeysNames.apkamSymmetricKey) {
      return atChopsKeys.apkamSymmetricKey!;
    }
    return null;
  }

  AtSigningAlgorithm? _getSigningAlgorithm(AtSigningInput signingInput) {
    if (signingInput.signingAlgorithm != null) {
      return signingInput.signingAlgorithm;
    } else if (signingInput.signingMode != null &&
        signingInput.signingMode == AtSigningMode.pkam) {
      return PkamSigningAlgo(atChopsKeys.atPkamKeyPair! as AtRSAKeyPair,
          signingInput.hashingAlgoType);
    } else if (signingInput.signingMode != null &&
        signingInput.signingMode == AtSigningMode.data) {
      return DefaultSigningAlgo(
          atChopsKeys.atEncryptionKeyPair! as AtRSAKeyPair,
          signingInput.hashingAlgoType);
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
        return PkamSigningAlgo(atChopsKeys.atPkamKeyPair as AtRSAKeyPair,
            verificationInput.hashingAlgoType);
      } else {
        return PkamSigningAlgo(null, verificationInput.hashingAlgoType);
      }
    } else if (verificationInput.signingMode != null &&
        verificationInput.signingMode == AtSigningMode.data &&
        atChopsKeys.atEncryptionKeyPair != null) {
      return DefaultSigningAlgo(atChopsKeys.atEncryptionKeyPair as AtRSAKeyPair,
          verificationInput.hashingAlgoType);
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
