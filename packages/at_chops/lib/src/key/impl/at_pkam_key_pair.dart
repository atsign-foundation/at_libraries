import 'package:at_chops/src/key/at_key_pair.dart';

class AtPkamKeyPair extends AsymmetricKeyPair {
  AtPkamKeyPair.create(String publicKey, String privateKey)
      : super.create(publicKey, privateKey);
}
