import 'package:at_chops/src/key/key_type.dart';

/// Class which represents metadata for data signing.
class AtSigningMetaData {
  String atSigningAlgorithm;
  SigningKeyType signingKeyType;
  ///Timestamp of signature creation in UTC
  DateTime signatureTimestamp;
  ///Contains the Algorithm used and digestLength of this signature
  String signatureSpec;
  AtSigningMetaData(this.atSigningAlgorithm, this.signingKeyType, this.signatureTimestamp, this.signatureSpec);

  //TODO serialization/deserialization
}
