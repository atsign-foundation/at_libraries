import 'dart:async' show FutureOr;

// TODO drop atChops - this package should be upstream of at_chops
import 'package:at_chops/at_chops.dart' show AESKey, StringAESEncryptor;
import 'package:at_chops/types.dart' show AtChopsUtil;
import 'package:at_keychain/src/base64_encodeable_key.dart'
    show Base64EncodableKey;

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

  factory AtKeys.fromJson(Map json) => _AtKeys.fromJson(json);
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

class _AtKeys implements AtKeys {
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

  factory _AtKeys.fromJson(Map json) {
    Base64EncodableKey? keyOnly(dynamic value) =>
        value is String ? Base64EncodableKey.fromBase64(value) : null;
    var selfEncryptionKey = keyOnly(json['selfEncryptionKey']);

    String? Function(dynamic) decrypted;
    if (selfEncryptionKey == null) {
      decrypted = (_) => null;
    } else {
      // TODO want base64 not utf8 String in
      var aes = StringAESEncryptor(AESKey(selfEncryptionKey.base64));
      decrypted = (value) {
        if (value is! String) return null;
        return aes.decrypt(value, iv: AtChopsUtil.generateIVLegacy());
      };
    }

    // TODO continue
    // var apkamPublicKey = keyOnly(decrypted(
    // var apkamPrivateKey,
    // var sharedEncryptionPublicKey,
    // var sharedEncryptionPrivateKey,
  }

  Map<String, String> _dropNulls(Map<String, String?> json) {
    return (json..removeWhere((_, v) => v == null)) as Map<String, String>;
  }

  @override
  Map<String, String> toJson() {
    var json = {
      'pkamPublicKey': apkamPublicKey?.base64,
      'pkamPrivateKey': apkamPrivateKey?.base64,
      'encryptPublicKey': sharedEncryptionPublicKey?.base64,
      'encryptPrivateKey': sharedEncryptionPrivateKey?.base64,
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
  Map<String, String> toEncryptedJson() {
    if (selfEncryptionKey == null) {
      return _dropNulls({
        'apkamSymmetricKey': apkamSymmetricKey?.base64,
        'enrollmentId': enrollmentId,
      });
    }
    // TODO want base64 not utf8 String out
    var aes = StringAESEncryptor(AESKey(selfEncryptionKey!.base64));
    encrypted(Base64EncodableKey? value) {
      if (value == null) return null;
      return aes.encrypt(value.base64, iv: AtChopsUtil.generateIVLegacy());
    }

    var json = {
      'aesPkamPublicKey': encrypted(apkamPublicKey),
      'aesPkamPrivateKey': encrypted(apkamPrivateKey),
      'aesEncryptPublicKey': encrypted(sharedEncryptionPublicKey),
      'aesEncryptPrivateKey': encrypted(sharedEncryptionPrivateKey),
      'selfEncryptionKey': selfEncryptionKey?.base64,
      'apkamSymmetricKey': apkamSymmetricKey?.base64,
      'enrollmentId': enrollmentId,
    };
    return _dropNulls(json);
  }
}
