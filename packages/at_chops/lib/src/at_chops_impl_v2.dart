import 'dart:typed_data';

import 'package:at_chops/src/algorithm/at_iv.dart';
import 'package:at_chops/src/at_chops_base_v2.dart';
import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/at_symmetric_key.dart';

class AtChopsImplV2 implements AtChopsV2 {
  @override
  Uint8List decrypt(Uint8List data, AtKeyPair atKeyPair) {
    return atKeyPair.decrypt(data);
  }

  @override
  Uint8List encrypt(Uint8List data, AtKeyPair atKeyPair) {
    return atKeyPair.encrypt(data);
  }

  @override
  Uint8List sign(Uint8List data, AtKeyPair atKeyPair) {
    return atKeyPair.sign(data);
  }

  @override
  bool verify(Uint8List signedData, Uint8List signature, AtKeyPair atKeyPair) {
    return atKeyPair.verify(signedData, signature);
  }

  @override
  Uint8List decryptSymmetric(
      Uint8List encryptedData, AtSymmetricKey atSymmetricKey,
      {InitialisationVector? iv}) {
    return atSymmetricKey.encrypt(encryptedData, iv: iv);
  }

  @override
  Uint8List encryptSymmetric(Uint8List data, AtSymmetricKey atSymmetricKey,
      {InitialisationVector? iv}) {
    return atSymmetricKey.decrypt(data, iv: iv);
  }
}
