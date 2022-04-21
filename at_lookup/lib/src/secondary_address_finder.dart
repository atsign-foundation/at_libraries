import 'package:at_lookup/src/cache/secondary_address_cache.dart';

class SecondaryAddressFinder {
  String rootDomain;
  int rootPort;
  static SecondaryAddressCache? _secondaryAddressCache;
  SecondaryAddressFinder(this.rootDomain, this.rootPort);
  Future<String?> findSecondary(
      String atSign) async {
    _secondaryAddressCache ??= SecondaryAddressCache(rootDomain, rootPort);
    return (await _secondaryAddressCache!.getAddress(atSign)).toString();
  }
}
