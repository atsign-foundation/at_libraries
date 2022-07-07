import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/cache/cacheable_secondary_address_finder.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:mocktail/mocktail.dart';

class MockSecondaryFinder extends Mock implements SecondaryUrlFinder {}

void main() async {
  group('this should be moved to functional tests', () {
    test('look up @cicd1 from root.atsign.wtf:64', () async {
      var secondaryAddress =
          await CacheableSecondaryAddressFinder('root.atsign.wtf', 64)
              .findSecondary('@cicd1');
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      print(secondaryAddress.toString());
    });
  });

  group('some cache tests with a MockSecondaryFinder', () {
    String rootDomain = 'root.atsign.unit.tests';
    int rootPort = 64;

    SecondaryUrlFinder mockSecondaryFinder = MockSecondaryFinder();

    String _addressFromAtSign(String atSign) {
      if (atSign.startsWith('@')) {
        atSign = atSign.replaceFirst('@', '');
      }
      return '$atSign.secondaries.unit.tests:1001';
    }

    late CacheableSecondaryAddressFinder cache;

    setUp(() {
      reset(mockSecondaryFinder);
      when(() => mockSecondaryFinder
              .findSecondaryUrl(any(that: startsWith('registered'))))
          .thenAnswer((invocation) async =>
              _addressFromAtSign(invocation.positionalArguments.first));
      when(() => mockSecondaryFinder
              .findSecondaryUrl(any(that: startsWith('notCached'))))
          .thenAnswer((invocation) async =>
              _addressFromAtSign(invocation.positionalArguments.first));
      when(() => mockSecondaryFinder
              .findSecondaryUrl(any(that: startsWith('notRegistered'))))
          .thenAnswer((invocation) async {
        throw SecondaryNotFoundException(
            CacheableSecondaryAddressFinder.getNotFoundExceptionMessage(
                invocation.positionalArguments.first));
      });

      cache = CacheableSecondaryAddressFinder(rootDomain, rootPort,
          secondaryFinder: mockSecondaryFinder);
    });

    test('test simple lookup for @registeredAtSign1', () async {
      var atSign = '@registeredAtSign1';
      var secondaryAddress = await cache.findSecondary(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test simple lookup for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      var secondaryAddress = await cache.findSecondary(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test simple lookup for notRegisteredAtSign1', () async {
      var atSign = 'notRegisteredAtSign1';
      expect(
          () async => await cache.findSecondary(atSign),
          throwsA(predicate((e) =>
              e is SecondaryNotFoundException &&
              e.message ==
                  CacheableSecondaryAddressFinder.getNotFoundExceptionMessage(
                      atSign))));
    });
    test('test isCached for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      await cache.findSecondary(atSign);
      expect(cache.cacheContains(atSign), true);
    });
    test('test isCached for notRegisteredAtSign1', () async {
      var atSign = 'notRegisteredAtSign1';
      expect(cache.cacheContains(atSign), false);
    });

    test('test expiry time - default cache expiry for registeredAtSign1',
        () async {
      var atSign = 'registeredAtSign1';
      await cache.findSecondary(atSign);
      final approxExpiry =
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;
      expect(cache.getCacheExpiryTime(atSign), isNotNull);
      expect((approxExpiry - cache.getCacheExpiryTime(atSign)!) < 100, true);
    });

    // TODO Why are these tests commented out?
//    test('test expiry time  - custom cache expiry for registeredAtSign1',
//        () async {
//      var atSign = 'registeredAtSign1';
//      await cache.findSecondary(atSign, cacheFor: Duration(seconds: 30));
//      final approxExpiry =
//          DateTime.now().add(Duration(seconds: 30)).millisecondsSinceEpoch;
//      expect(cache.getCacheExpiryTime(atSign), isNotNull);
//      expect((approxExpiry - cache.getCacheExpiryTime(atSign)!) < 100, true);
//    });

//    test('test update cache for atsign which is not yet cached', () async {
//      var atSign = 'notCachedAtSign1';
//      expect(cache.cacheContains(atSign), false);
//      await cache.findSecondary(atSign, refreshCacheNow: true);
//      expect(cache.cacheContains(atSign), true);
//    });
  });

  group('some cache tests with a real SecondaryUrlFinder but with rootDomain set to proxy:<something>', () {
    String proxyHost = 'vip.ve.atsign.zone';
    String rootDomain = 'proxy:$proxyHost';
    int rootPort = 8443;

    String _addressFromAtSign(String atSign) {
      return '$proxyHost:$rootPort';
    }

    late CacheableSecondaryAddressFinder cache;

    setUp(() {
      cache = CacheableSecondaryAddressFinder(rootDomain, rootPort);
    });

    test('test simple lookup for @registeredAtSign1', () async {
      var atSign = '@registeredAtSign1';
      var secondaryAddress = await cache.findSecondary(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test simple lookup for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      var secondaryAddress = await cache.findSecondary(atSign);
      expect(secondaryAddress.port, isNotNull);
      expect(secondaryAddress.host, isNotNull);
      expect(secondaryAddress.toString(), _addressFromAtSign(atSign));
    });
    test('test isCached for registeredAtSign1', () async {
      var atSign = 'registeredAtSign1';
      await cache.findSecondary(atSign);
      expect(cache.cacheContains(atSign), true);
    });

    test('test expiry time - default cache expiry for registeredAtSign1',
        () async {
      var atSign = 'registeredAtSign1';
      await cache.findSecondary(atSign);
      final approxExpiry =
          DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch;
      expect(cache.getCacheExpiryTime(atSign), isNotNull);
      expect((approxExpiry - cache.getCacheExpiryTime(atSign)!) < 100, true);
    });
  });
}
