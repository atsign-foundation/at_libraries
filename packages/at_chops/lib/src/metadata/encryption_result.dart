import 'package:at_chops/src/metadata/encryption_metadata.dart';

// Class that contains the encryption/decryption result with data type [AtEncryptionDataType] and metadata [AtEncryptionMetaData]
class AtEncryptionResult {
  late AtEncryptionDataType atEncryptionDataType;
  dynamic result;
  late AtEncryptionMetaData atEncryptionMetaData;
}

enum AtEncryptionDataType { bytes, string }
