/// Represents a private key from [AtKeyPair]
class AtPrivateKey {
  late String _privateKey;
  AtPrivateKey.fromString(this._privateKey);
  String get privateKey => _privateKey;
}
