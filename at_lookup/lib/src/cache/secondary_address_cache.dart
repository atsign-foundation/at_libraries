import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/util/lookup_util.dart';
import 'package:at_utils/at_logger.dart';

class SecondaryAddressCache {
  static const Duration defaultCacheDuration = Duration(hours: 1);

  final Map<String, SecondaryAddressCacheEntry> _map = {};
  final _logger = AtSignLogger('SecondaryAddressCacheImpl');

  final String _rootDomain;
  final int _rootPort;
  late SecondaryAddressFinder _secondaryFinder;

  SecondaryAddressCache(this._rootDomain, this._rootPort, {SecondaryAddressFinder? secondaryFinder}) {
    _secondaryFinder = secondaryFinder ?? SecondaryAddressFinder();
  }

  bool cacheContains(String atSign) {
    return _map.containsKey(stripAtSignFromAtSign(atSign));
  }

  /// Returns the expiry time of this entry in millisecondsSinceEpoch, or null if this atSign is not in cache
  int? getCacheExpiryTime(String atSign) {
    atSign = stripAtSignFromAtSign(atSign);
    if (_map.containsKey(atSign)) {
      return _map[atSign]!.expiresAt;
    } else {
      return null;
    }
  }

  Future<SecondaryAddress> getAddress(String atSign, {bool refreshCacheNow = false, Duration cacheFor = defaultCacheDuration}) async {
    atSign = stripAtSignFromAtSign(atSign);

    if (refreshCacheNow || _cacheIsEmptyOrExpired(atSign)) {
      // _updateCache will either populate the cache, or throw an exception
      await _updateCache(atSign, cacheFor);
    }

    if (_map.containsKey(atSign)) {
      // should always be true, since _updateCache will throw an exception if it fails
      return _map[atSign]!.secondaryAddress;
    } else {
      // but just in case, we'll throw an exception if it's not
      throw Exception("Failed to find secondary, in a theoretically impossible way");
    }
  }

  bool _cacheIsEmptyOrExpired(String atSign) {
    if (_map.containsKey(atSign)) {
      SecondaryAddressCacheEntry entry = _map[atSign]!;
      if (entry.expiresAt < DateTime.now().millisecondsSinceEpoch) {
        // expiresAt is in the past - cache has expired
        return true;
      } else {
        // cache has not yet expired
        return false;
      }
    } else {
      // cache is empty
      return true;
    }
  }

  static String stripAtSignFromAtSign(String atSign) {
    if (atSign.startsWith('@')) {
      atSign = atSign.replaceFirst('@', '');
    }
    return atSign;
  }
  static String getNotFoundExceptionMessage(String atSign) {
    return 'Unable to find secondary address for atSign:$atSign';
  }
  Future<void> _updateCache(String atSign, Duration cacheFor) async {
    try {
      String? secondaryUrl = await _secondaryFinder.findSecondary(atSign, _rootDomain, _rootPort);
      if (secondaryUrl == null ||
          secondaryUrl.isEmpty ||
          secondaryUrl == 'data:null') {
        throw SecondaryNotFoundException(getNotFoundExceptionMessage(atSign));
      }
      var secondaryInfo = LookUpUtil.getSecondaryInfo(secondaryUrl);
      String secondaryHost = secondaryInfo[0];
      int secondaryPort = int.parse(secondaryInfo[1]);

      SecondaryAddress addr = SecondaryAddress(secondaryHost, secondaryPort);
      _map[atSign] = SecondaryAddressCacheEntry(addr, DateTime.now().add(cacheFor).millisecondsSinceEpoch);
    } on Exception catch (e) {
      _logger.severe('${getNotFoundExceptionMessage(atSign)} - ${e.toString()}');
      rethrow;
    }
  }
}

class SecondaryAddress {
  final String host;
  final int port;
  SecondaryAddress(this.host, this.port);

  @override
  String toString() {
    return '$host:$port';
  }
}

class SecondaryAddressCacheEntry {
  final SecondaryAddress secondaryAddress;
  /// milliseconds since epoch
  final int expiresAt;

  SecondaryAddressCacheEntry(this.secondaryAddress, this.expiresAt);
}

class SecondaryAddressFinder {
  Future<String?> findSecondary(String atSign, String rootDomain, int rootPort) async {
    return await AtLookupImpl.findSecondary(atSign, rootDomain, rootPort);
  }
}