import 'dart:async' show FutureOr;
import 'dart:convert';

import 'package:at_keychain/src/base64_encodeable_key.dart'
    show Base64EncodableKey;
import 'package:at_utils/at_utils.dart' show AtSignLogger;
import 'package:better_cryptography/better_cryptography.dart'
    show AesCtr, MacAlgorithm, SecretKey, Mac, SecretBox;

/// Defines the contents of the .atKeys file / an atSign's keys in the keychain
abstract class AtKeys {
  Base64EncodableKey? get apkamPublicKey;
  Base64EncodableKey? get apkamPrivateKey;
  Base64EncodableKey? get sharedEncryptionPublicKey;
  Base64EncodableKey? get sharedEncryptionPrivateKey;
  Base64EncodableKey? get selfEncryptionKey;
  Base64EncodableKey? get apkamSymmetricKey;
  String? get enrollmentId;

  Map<String, String> toJson();
  FutureOr<Map<String, String>> toEncryptedJson();

  static Future<AtKeys> fromJson(Map json) => _AtKeys.fromJson(json);
  factory AtKeys({
    Base64EncodableKey? apkamPublicKey,
    Base64EncodableKey? apkamPrivateKey,
    Base64EncodableKey? sharedEncryptionPublicKey,
    Base64EncodableKey? sharedEncryptionPrivateKey,
    Base64EncodableKey? selfEncryptionKey,
    Base64EncodableKey? apkamSymmetricKey,
    String? enrollmentId,
  }) =>
      _AtKeys(
        apkamPublicKey: apkamPublicKey,
        apkamPrivateKey: apkamPrivateKey,
        sharedEncryptionPublicKey: sharedEncryptionPublicKey,
        sharedEncryptionPrivateKey: sharedEncryptionPrivateKey,
        selfEncryptionKey: selfEncryptionKey,
        apkamSymmetricKey: apkamSymmetricKey,
        enrollmentId: enrollmentId,
      );
}

// TODO:
// KeyChainManager also stores :
// "hiveSecret": hiveSecret,
// "secret": secret,
// What do we do with these fields?
class _AtKeys implements AtKeys {
  static final AtSignLogger _logger = AtSignLogger('AtKeys');
  @override
  final Base64EncodableKey? apkamPublicKey;
  @override
  final Base64EncodableKey? apkamPrivateKey;
  @override
  final Base64EncodableKey? sharedEncryptionPublicKey;
  @override
  final Base64EncodableKey? sharedEncryptionPrivateKey;
  @override
  final Base64EncodableKey? selfEncryptionKey;
  @override
  final Base64EncodableKey? apkamSymmetricKey;
  @override
  final String? enrollmentId;

  const _AtKeys({
    this.apkamPublicKey,
    this.apkamPrivateKey,
    this.sharedEncryptionPublicKey,
    this.sharedEncryptionPrivateKey,
    this.selfEncryptionKey,
    this.apkamSymmetricKey,
    this.enrollmentId,
  });

  static List<int> get _emptyNonce =>
      const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  static Future<_AtKeys> fromJson(Map json) async {
    Base64EncodableKey? toBase64KeyOrNull(dynamic value) {
      if (value is String) return Base64EncodableKey.fromBase64(value);
      if (value is List<int>) return Base64EncodableKey.fromBytes(value);
      return null;
    }

    String? asStringOrNull(dynamic value) => value is String ? value : null;

    var selfEncryptionKey = toBase64KeyOrNull(json['selfEncryptionKey']);
    Base64EncodableKey? apkamPublicKey,
        apkamPrivateKey,
        sharedEncryptionPrivateKey,
        sharedEncryptionPublicKey,
        apkamSymmetricKey;

    // Function which decrypts a potential key, otherwise yields null
    Future<List<int>?> Function(dynamic) decrypted;
    if (selfEncryptionKey == null) {
      decrypted = (_) async => null;
    } else {
      var aes = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
      var secretKey = SecretKey(selfEncryptionKey.bytes);
      decrypted = (keyName) async {
        var value = json[keyName];
        if (value is! String) return null;
        try {
          var sBox = SecretBox(base64Decode(value),
              nonce: _emptyNonce, mac: Mac.empty);
          return await aes.decrypt(sBox, secretKey: secretKey);
        } catch (e, s) {
          _logger.severe("Failed to decrypt key: $keyName", e, s);
          return null;
        }
      };
      apkamPublicKey = toBase64KeyOrNull(
        json['pkamPublicKey'] ?? await decrypted('aesPkamPublicKey'),
      );
      apkamPrivateKey = toBase64KeyOrNull(
        json['pkamPrivateKey'] ?? await decrypted('aesPkamPrivateKey'),
      );
      sharedEncryptionPublicKey = toBase64KeyOrNull(
        json['encryptionPublicKey'] ?? await decrypted('aesEncryptPublicKey'),
      );
      sharedEncryptionPrivateKey = toBase64KeyOrNull(
        json['encryptionPrivateKey'] ?? await decrypted('aesEncryptPrivateKey'),
      );
    }

    return _AtKeys(
      apkamPublicKey: apkamPublicKey,
      apkamPrivateKey: apkamPrivateKey,
      sharedEncryptionPublicKey: sharedEncryptionPublicKey,
      sharedEncryptionPrivateKey: sharedEncryptionPrivateKey,
      selfEncryptionKey: selfEncryptionKey,
      apkamSymmetricKey: apkamSymmetricKey,
      enrollmentId: asStringOrNull(json['enrollmentId']),
    );
  }

  Map<String, String> _dropNulls(Map<String, String?> json) {
    return (json..removeWhere((_, v) => v == null)) as Map<String, String>;
  }

  @override
  Map<String, String> toJson() {
    // Field names originate from how they are stored in a native keychain
    var json = {
      'pkamPublicKey': apkamPublicKey?.base64,
      'pkamPrivateKey': apkamPrivateKey?.base64,
      'encryptionPublicKey': sharedEncryptionPublicKey?.base64,
      'encryptionPrivateKey': sharedEncryptionPrivateKey?.base64,
      'selfEncryptionKey': selfEncryptionKey?.base64,
      'apkamSymmetricKey': apkamSymmetricKey?.base64,
      'enrollmentId': enrollmentId,
    };
    return _dropNulls(json);
  }

  @override
  // TODO: deprecate this... literally no point in encrypting something if the
  // decryption key is stored in the same place
  // We should wait a while before we replace writing of non-encrypted key files
  // however we should support reading immediately so it has time to propogate
  Future<Map<String, String>> toEncryptedJson() async {
    if (selfEncryptionKey == null) {
      return _dropNulls({
        'apkamSymmetricKey': apkamSymmetricKey?.base64,
        'enrollmentId': enrollmentId,
      });
    }
    var aes = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);
    var secretKey = SecretKey(selfEncryptionKey!.bytes);
    encrypted(Base64EncodableKey? value, String keyName) async {
      if (value == null) return null;
      try {
        var sBox = await aes.encrypt(
          base64Encode(value.bytes).codeUnits,
          secretKey: secretKey,
          nonce: [0],
        );
        return base64Encode(sBox.cipherText);
      } catch (e, s) {
        _logger.severe("Failed to encrypt key: $keyName", e, s);
        return null;
      }
    }

    // Field names originate from how they are stored in .atKeys
    var json = {
      'aesPkamPublicKey': await encrypted(apkamPublicKey, "pkam public key"),
      'aesPkamPrivateKey': await encrypted(apkamPrivateKey, "pkam private key"),
      'aesEncryptPublicKey': await encrypted(
          sharedEncryptionPublicKey, "shared encryption public key"),
      'aesEncryptPrivateKey': await encrypted(
          sharedEncryptionPrivateKey, "shared encryption private key"),
      'selfEncryptionKey': selfEncryptionKey?.base64,
      'apkamSymmetricKey': apkamSymmetricKey?.base64,
      'enrollmentId': enrollmentId,
    };
    return _dropNulls(json);
  }
}
