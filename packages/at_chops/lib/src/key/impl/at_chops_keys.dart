import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/impl/at_signing_key_pair.dart';

class AtChopsKeys {
  AtEncryptionKeyPair? atEncryptionKeyPair;

  AtPkamKeyPair? _atPkamKeyPair;
  AtSigningKeyPair? atSigningKeyPair;

  @Deprecated('Use selfEncryptionKey')
  SymmetricKey? symmetricKey;

  SymmetricKey? selfEncryptionKey;

  SymmetricKey? apkamSymmetricKey;

  AtChopsKeys.create(this.atEncryptionKeyPair, this._atPkamKeyPair);

  AtChopsKeys();

  @Deprecated('Use selfEncryptionKey')
  AtChopsKeys.createSymmetric(this.symmetricKey);

  AtPkamKeyPair? get atPkamKeyPair => _atPkamKeyPair;
}
