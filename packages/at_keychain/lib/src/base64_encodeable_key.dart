import 'dart:convert' show base64Decode, base64Encode;
import 'dart:typed_data' show Uint8List;

sealed class Base64EncodableKey {
  factory Base64EncodableKey.fromBase64(String base64,
      {bool persistDecoded = false}) {
    if (persistDecoded) {
      return Base64EncodableKey.fromBytes(
        base64Decode(base64),
        persistEncoded: false,
      );
    }
    return _Base64Key(base64);
  }

  factory Base64EncodableKey.fromBytes(Uint8List bytes,
      {bool persistEncoded = false}) {
    if (persistEncoded) {
      return Base64EncodableKey.fromBase64(
        base64Encode(bytes),
        persistDecoded: false,
      );
    }
    return _RawKey(bytes);
  }

  String get base64;
  Uint8List get bytes;
}

final class _Base64Key implements Base64EncodableKey {
  final String _base64;
  const _Base64Key(this._base64);
  @override
  String get base64 => _base64;

  @override
  Uint8List get bytes => base64Decode(_base64);
}

final class _RawKey implements Base64EncodableKey {
  final Uint8List _bytes;
  const _RawKey(this._bytes);
  @override
  String get base64 => base64Encode(_bytes);

  @override
  Uint8List get bytes => _bytes;
}
