import 'package:at_chops/src/key/at_private_key.dart';

class CramKey implements AtPrivateKey {
  late String _cramSecret;
  CramKey.fromString(String secret) {
    _cramSecret = secret;
  }
}
