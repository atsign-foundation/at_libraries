import 'package:at_keychain/src/keychain.dart' show Keychain;

// NOTE: maybe single instance is preferrable
// but also, it may be useful to read from multiple places
// in the event that both Native keychain and a ubikey or something
// is available
// Maybe we need a write priority number or this needs to be a map with
// a name for the keychain?
// i.e. write in one keychain, but try reading from all
final List<Keychain> _registeredKeychains = [];

class KeychainRegistry {
  /// Adds a registered [Keychain] implementation
  void add(Keychain k) => _registeredKeychains.add(k);

  /// Clears all [Keychain] implementations from the registry
  void clear() => _registeredKeychains.clear();

  /// Remove all [Keychain]s from the registry that satisfy [test]
  void removeWhere(bool Function(Keychain) test) =>
      _registeredKeychains.removeWhere(test);

  Keychain get instance => const _UnifiedKeychain();
}

// For each [Keychain] method, iterates on [_registeredKeychains] and
// applies the method
class _UnifiedKeychain implements Keychain {
  const _UnifiedKeychain();
}
