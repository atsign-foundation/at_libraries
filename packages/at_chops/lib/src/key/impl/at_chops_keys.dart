import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/impl/at_signing_key_pair.dart';

class AtChopsKeys {
  AtEncryptionKeyPair? _atEncryptionKeyPair;

  AtEncryptionKeyPair? get atEncryptionKeyPair => _atEncryptionKeyPair;
  AtPkamKeyPair? _atPkamKeyPair;
  AtSigningKeyPair? atSigningKeyPair;
  SymmetricKey? symmetricKey;

  AtChopsKeys.create(this._atEncryptionKeyPair, this._atPkamKeyPair);

  AtPkamKeyPair? get atPkamKeyPair => _atPkamKeyPair;
}
