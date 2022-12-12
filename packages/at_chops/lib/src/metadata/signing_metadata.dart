import 'package:at_chops/src/key/key_type.dart';

/// Class which represents metadata for data signing.
class AtSigningMetaData {
  String atSigningAlgorithm;
  SigningKeyType signingKeyType;
  AtSigningMetaData(this.atSigningAlgorithm, this.signingKeyType);
}