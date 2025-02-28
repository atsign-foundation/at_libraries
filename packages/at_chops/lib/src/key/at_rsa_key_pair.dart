import 'dart:convert';
import 'dart:typed_data';

import 'package:at_chops/src/key/asymmetric_key_pair.dart';

class AtRSAKeyPair extends AsymmetricKeyPair<AtRSAPublicKey, AtRSAPrivateKey> {
  AtRSAKeyPair(super.publicKey, super.privateKey);
  AtRSAKeyPair.create(String publicKey, String privateKey)
      : super(AtRSAPublicKey(publicKey), AtRSAPrivateKey(privateKey));
}

class AtRSAPublicKey extends AtPublicKey {
  @override
  final Uint8List raw;

  AtRSAPublicKey(String base64) : raw = base64Decode(base64);
  AtRSAPublicKey.raw(this.raw);

  @override
  String get publicKey => base64Encode(raw);
}

class AtRSAPrivateKey extends AtPrivateKey {
  @override
  final Uint8List raw;
  AtRSAPrivateKey(String base64) : raw = base64Decode(base64);
  AtRSAPrivateKey.raw(this.raw);

  @override
  String get privateKey => base64Encode(raw);
}
