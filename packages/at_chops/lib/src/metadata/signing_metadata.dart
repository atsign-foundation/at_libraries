import 'package:at_chops/src/algorithm/algo_type.dart';

/// Class which represents metadata for data signing.
class AtSigningMetaData {
  HashingAlgoType? hashingAlgoType;
  SigningAlgoType? signingAlgoType;

  ///Timestamp of signature creation in UTC
  DateTime signatureTimestamp;

  AtSigningMetaData(
      this.signingAlgoType, this.hashingAlgoType, this.signatureTimestamp);

  //TODO serialization/deserialization
}
