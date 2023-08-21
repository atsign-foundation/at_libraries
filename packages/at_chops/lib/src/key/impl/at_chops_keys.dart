import 'package:at_chops/src/key/at_key_pair.dart';
import 'package:at_chops/src/key/impl/at_encryption_key_pair.dart';
import 'package:at_chops/src/key/impl/at_pkam_key_pair.dart';
import 'package:at_chops/src/key/impl/at_signing_key_pair.dart';

class AtChopsKeys {
  /// Default encryption key pair
  AtEncryptionKeyPair? atEncryptionKeyPair;

  /// Key pair for pkam authentication. Can be legacy pkam keypair or apkam keypair for new enrollment
  AtPkamKeyPair? _atPkamKeyPair;

  /// Key pair for data signing and verification
  AtSigningKeyPair? atSigningKeyPair;

  @Deprecated('Use selfEncryptionKey')
  SymmetricKey? get symmetricKey => selfEncryptionKey;

  @Deprecated('Use selfEncryptionKey')
  void set symmetricKey(SymmetricKey? sk) => selfEncryptionKey = sk;

  /// Default self encryption key
  SymmetricKey? selfEncryptionKey;

  /// APKAM symmetric key created during new enrollment
  SymmetricKey? apkamSymmetricKey;

  AtChopsKeys.create(this.atEncryptionKeyPair, this._atPkamKeyPair);

  AtChopsKeys();

  @Deprecated('Use selfEncryptionKey')
  AtChopsKeys.createSymmetric(SymmetricKey sk) {
    selfEncryptionKey = sk;
  }

  AtPkamKeyPair? get atPkamKeyPair => _atPkamKeyPair;
}
