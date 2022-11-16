
import 'package:at_chops/src/key/at_encryption_key.dart';

class CramKey extends AtEncryptionKey {
  final String _cramSecret;
  CramKey(this._cramSecret);
  String get secret => _cramSecret;
}
