import 'package:at_chops/src/key/key.dart';

class AtChopsKeys {
  /// Default encryption key pair
  AsymmetricKeyPair? atEncryptionKeyPair;

  /// Key pair for pkam authentication. Can be legacy pkam keypair or apkam keypair for new enrollment
  AsymmetricKeyPair? _atPkamKeyPair;

  /// Key pair for data signing and verification
  AsymmetricKeyPair? atSigningKeyPair;

  /// Default self encryption key
  SymmetricKey? selfEncryptionKey;

  /// APKAM symmetric key created during new enrollment
  SymmetricKey? apkamSymmetricKey;

  /// EnrollmentId associated with pkam keys
  String? enrollmentId;

  AtChopsKeys.create(this.atEncryptionKeyPair, this._atPkamKeyPair);

  AtChopsKeys();

  AsymmetricKeyPair? get atPkamKeyPair => _atPkamKeyPair;
}
