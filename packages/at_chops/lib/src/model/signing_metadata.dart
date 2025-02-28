import 'package:at_chops/src/hashing/hashing.dart';
import 'package:at_chops/src/signing/at_signing_algorithm.dart';

/// Class which represents metadata for data signing.
class AtSigningMetaData {
  HashingAlgoType? hashingAlgoType;
  SigningAlgoType? signingAlgoType;

  ///Timestamp of signature creation in UTC
  DateTime signatureTimestamp;

  AtSigningMetaData(
      this.signingAlgoType, this.hashingAlgoType, this.signatureTimestamp);

  @override
  toString() {
    return 'HashingAlgo: ${hashingAlgoType?.name}, '
        'SigningAlgo: ${signingAlgoType?.name}, '
        'SignatureTimestamp: ${signatureTimestamp.toString()}';
  }
}
