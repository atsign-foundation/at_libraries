import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/util/lookup_util.dart';
import 'package:at_utils/at_logger.dart';

abstract class SecondaryAddressCache {
  Future<SecondaryAddress> getAddress(
      String atSign, String rootDomain, int rootPort);
}

class SecondaryAddress {
  final String host;
  final int port;
  SecondaryAddress(this.host, this.port);

  @override
  String toString() {
    return 'SecondaryAddress{host: $host, port: $port}';
  }
}

class SecondaryAddressCacheImpl implements SecondaryAddressCache {
  final Map<String, SecondaryAddress> _map = {};
  static final _logger = AtSignLogger('SecondaryAddressCacheImpl');

  static final int expiryHrs = 1;
  static final SecondaryAddressCacheImpl _singleton =
      SecondaryAddressCacheImpl._internal();

  factory SecondaryAddressCacheImpl.getInstance() {
    return _singleton;
  }

  SecondaryAddressCacheImpl._internal();

  @override
  Future<SecondaryAddress> getAddress(
      String atSign, String rootDomain, int rootPort) async {
    if (_map.containsKey(atSign)) {
      return _map[atSign]!;
    }
    try {
      String? secondaryUrl =
          await AtLookupImpl.findSecondary(atSign, rootDomain, rootPort);
      if (secondaryUrl == null ||
          secondaryUrl.isEmpty ||
          secondaryUrl == 'data:null') {
        throw SecondaryNotFoundException(
            'Unable find secondary url for atSign:$atSign');
      }
      var secondaryInfo = LookUpUtil.getSecondaryInfo(secondaryUrl);
      String secondaryHost = secondaryInfo[0];
      int secondaryPort = int.parse(secondaryInfo[1]);
      _add(atSign, SecondaryAddress(secondaryHost, secondaryPort));
    } on Exception catch (e) {
      _logger.severe(
          'unable to find secondary address for atSign:$atSign - ${e.toString()}');
      rethrow;
    }
    return _map[atSign]!;
  }

  void _add(String atSign, SecondaryAddress address) {
    _map[atSign] = address;
    Future.delayed(Duration(hours: expiryHrs), () => _remove(atSign));
  }

  void _remove(String atSign) {
    _map.remove(atSign);
  }
}
