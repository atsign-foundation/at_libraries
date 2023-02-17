import 'package:at_chops/src/metadata/signing_metadata.dart';

// Class that contains the signing/verification result with data type [AtSigningResultType] and metadata [AtSigningMetaData]
class AtSigningResult {
  late AtSigningResultType atSigningResultType;
  dynamic result;
  late AtSigningMetaData atSigningMetaData;

  //TODO serialization/deserialization
}

enum AtSigningResultType { bytes, string, bool }
