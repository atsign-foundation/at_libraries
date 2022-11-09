import 'package:at_chops/src/key/at_private_key.dart';
import 'package:at_chops/src/key/at_public_key.dart';

abstract class AtKeyPair {
  AtKeyPair(AtPrivateKey atPrivateKey, AtPublicKey atPublicKey);
}
