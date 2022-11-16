import 'dart:typed_data';

abstract class AtPublicKey {
  AtPublicKey.fromString(String atPublicKey);
  bool verifySHA256Signature(Uint8List message, Uint8List signature);
  /// Encrypts the passed bytes. Bytes are passed as [Uint8List]. Encode String data type to [Uint8List] using [utf8.encode].
  Uint8List encrypt(Uint8List data);

}
