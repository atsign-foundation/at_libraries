import 'package:at_chops/src/key/at_private_key.dart';

class CramKey implements AtPrivateKey {
  final String _cramSecret;
  CramKey(this._cramSecret);
  String get secret => _cramSecret;
}
