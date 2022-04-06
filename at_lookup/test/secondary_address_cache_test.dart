import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/cache/secondary_address_cache.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:mocktail/mocktail.dart';

class MockSecondaryFinder extends Mock implements SecondaryAddressFinder {}

void main() async {
  String rootDomain = 'root.atsign.unit.tests';
  int rootPort = 64;
  SecondaryAddressFinder mockSecondaryFinder = MockSecondaryFinder();

  String _addressFromAtSign(String atSign) {
    if (atSign.startsWith('@')) {
      atSign = atSign.replaceFirst('@', '');
    }
    return '$atSign.secondaries.unit.tests:1001';
  }

  group('this should be moved to functional tests', () {
    test('look up @cicd1 from root.atsign.wtf:64', () async {
      var secondaryAddress = await SecondaryAddressCache('root.atsign.wtf', 64)
          .getAddress('@cicd1');
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      print(secondaryAddress.toString());
    });
  });

  group('some cache tests', () {
    late SecondaryAddressCache cache;

    setUp(() {
      reset(mockSecondaryFinder);
      when(() => mockSecondaryFinder.findSecondary(
              any(that: startsWith('registered')), rootDomain, rootPort))
          .thenAnswer((invocation) async =>
              _addressFromAtSign(invocation.positionalArguments.first));
      when(() => mockSecondaryFinder.findSecondary(
              any(that: startsWith('notCached')), rootDomain, rootPort))
          .thenAnswer((invocation) async =>
              _addressFromAtSign(invocation.positionalArguments.first));
      when(() => mockSecondaryFinder.findSecondary(
              any(that: startsWith('notRegistered')), rootDomain, rootPort))
          .thenAnswer((invocation) async {
        throw SecondaryNotFoundException(
            SecondaryAddressCache.getNotFoundExceptionMessage(
                invocation.positionalArguments.first));
      });

      cache = SecondaryAddressCache(rootDomain, rootPort,
          secondaryFinder: mockSecondaryFinder);
    });

    test('test simple lookup for @registeredAtSign1', () async {
      var atSign = '@registeredAtSign1';
      var secondaryAddress = await cache.getAddress(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test simple lookup for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      var secondaryAddress = await cache.getAddress(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test simple lookup for notRegisteredAtSign1', () async {
      var atSign = 'notRegisteredAtSign1';
      expect(
          () async => await cache.getAddress(atSign),
          throwsA(predicate((e) =>
              e is SecondaryNotFoundException &&
              e.message ==
                  SecondaryAddressCache.getNotFoundExceptionMessage(atSign))));
    });
    test('test isCached for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      await cache.getAddress(atSign);
      expect(cache.cacheContains(atSign), true);
    });
    test('test isCached for notRegisteredAtSign1', () async {
      var atSign = 'notRegisteredAtSign1';
      expect(cache.cacheContains(atSign), false);
    });

    test('test expiry time - default cache expiry for registeredAtSign1',
        () async {
      var atSign = 'registeredAtSign1';
      await cache.getAddress(atSign);
      final approxExpiry =
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;
      expect(cache.getCacheExpiryTime(atSign), isNotNull);
      expect((approxExpiry - cache.getCacheExpiryTime(atSign)!) < 100, true);
    });

    test('test expiry time  - custom cache expiry for registeredAtSign1',
        () async {
      var atSign = 'registeredAtSign1';
      await cache.getAddress(atSign, cacheFor: Duration(seconds: 30));
      final approxExpiry =
          DateTime.now().add(Duration(seconds: 30)).millisecondsSinceEpoch;
      expect(cache.getCacheExpiryTime(atSign), isNotNull);
      expect((approxExpiry - cache.getCacheExpiryTime(atSign)!) < 100, true);
    });

    test('test update cache for atsign which is not yet cached', () async {
      var atSign = 'notCachedAtSign1';
      expect(cache.cacheContains(atSign), false);
      await cache.getAddress(atSign, refreshCacheNow: true);
      expect(cache.cacheContains(atSign), true);
    });
  });
}
