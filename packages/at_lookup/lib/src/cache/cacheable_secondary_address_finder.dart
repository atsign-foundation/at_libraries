import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/util/lookup_util.dart';
import 'package:at_utils/at_logger.dart';

class CacheableSecondaryAddressFinder implements SecondaryAddressFinder {
  static const Duration defaultCacheDuration = Duration(hours: 1);

  final Map<String, SecondaryAddressCacheEntry> _map = {};
  final _logger = AtSignLogger('SecondaryAddressCacheImpl');

  final String _rootDomain;
  final int _rootPort;
  late SecondaryUrlFinder _secondaryFinder;

  CacheableSecondaryAddressFinder(this._rootDomain, this._rootPort,
      {SecondaryUrlFinder? secondaryFinder}) {
    _secondaryFinder =
        secondaryFinder ?? SecondaryUrlFinder(_rootDomain, _rootPort);
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

  @override
  Future<SecondaryAddress> findSecondary(String atSign) async {
    atSign = stripAtSignFromAtSign(atSign);

    if (_cacheIsEmptyOrExpired(atSign)) {
      // _updateCache will either populate the cache, or throw an exception
      await _updateCache(atSign, defaultCacheDuration);
    }
    if (_map.containsKey(atSign)) {
      // should always be true, since _updateCache will throw an exception if it fails
      return _map[atSign]!.secondaryAddress;
    } else {
      // but just in case, we'll throw an exception if it's not
      throw Exception(
          "Failed to find secondary, in a theoretically impossible way");
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
      String? secondaryUrl = await _secondaryFinder.findSecondaryUrl(atSign);
      if (secondaryUrl == null ||
          secondaryUrl.isEmpty ||
          secondaryUrl == 'data:null') {
        throw SecondaryNotFoundException(getNotFoundExceptionMessage(atSign));
      }
      var secondaryInfo = LookUpUtil.getSecondaryInfo(secondaryUrl);
      String secondaryHost = secondaryInfo[0];
      int secondaryPort = int.parse(secondaryInfo[1]);

      SecondaryAddress addr = SecondaryAddress(secondaryHost, secondaryPort);
      _map[atSign] = SecondaryAddressCacheEntry(
          addr, DateTime.now().add(cacheFor).millisecondsSinceEpoch);
    } on AtException {
      rethrow;
    } on Exception catch (e) {
      _logger
          .severe('${getNotFoundExceptionMessage(atSign)} - ${e.toString()}');
      throw AtException(e.toString());
    }
  }
}

class SecondaryAddressCacheEntry {
  final SecondaryAddress secondaryAddress;

  /// milliseconds since epoch
  final int expiresAt;

  SecondaryAddressCacheEntry(this.secondaryAddress, this.expiresAt);
}

/// When SecondaryUrlFinder tries to lookup the atServer's address from an
/// atDirectory, it may encounter intermittent failures for various reasons -
/// 'network weather', service glitches, etc.
///
/// In order to be resilient to such failures, we implement retries.
///
/// The static variable [retryDelaysMillis] controls
/// (a) how many retries are done, and
/// (b) the delay before each retry
class SecondaryUrlFinder {
  final String _rootDomain;
  final int _rootPort;
  late final AtLookupSecureSocketFactory _socketFactory;

  SecondaryUrlFinder(this._rootDomain, this._rootPort,
      {AtLookupSecureSocketFactory? socketFactory}) {
    _socketFactory = socketFactory ?? AtLookupSecureSocketFactory();
  }

  final _logger = AtSignLogger('SecondaryUrlFinder');

  /// Controls
  /// (a) how many retries are done, and
  /// (b) the delay before each retry
  static List<int> retryDelaysMillis = [50, 100, 150, 200];

  Future<String?> findSecondaryUrl(String atSign) async {
    if (_rootDomain.startsWith("proxy:")) {
      // In order to make it easy for clients to connect to a reverse proxy
      // instead of doing a root lookup,  we adopt the convention that:
      // if the rootDomain starts with 'proxy:'
      // then the secondary domain name will be deemed to be the portion of rootDomain after 'proxy:'
      // and the secondary port will be deemed to be the rootPort
      return '${_rootDomain.substring("proxy:".length)}:$_rootPort';
    }
    String? address;
    for (int i = 0; i <= retryDelaysMillis.length; i++) {
      try {
        address = await _findSecondary(atSign);
        return address;
      } catch (e) {
        if (i < retryDelaysMillis.length) {
          _logger.info('AtLookup.findSecondary for $atSign failed with $e'
              ' : will retry in ${retryDelaysMillis[i]} milliseconds');
          await Future.delayed(Duration(milliseconds: retryDelaysMillis[i]));
          continue;
        }
        _logger.severe('AtLookup.findSecondary for $atSign failed with $e'
            ' : ${retryDelaysMillis.length + 1} failures, giving up');
        if (e is RootServerConnectivityException) {
          throw RootServerConnectivityException(
              'Unable to establish connection with root server.'
              ' Please check your internet connection and try again');
        }
      }
    }
    throw AtConnectException('Could not fetch secondary address for $atSign :'
        ' ${retryDelaysMillis.length + 1} failures, giving up');
  }

  Future<String?> _findSecondary(String atsign) async {
    String? response;
    SecureSocket? socket;
    try {
      _logger.finer('findSecondaryUrl: received atsign: $atsign');
      if (atsign.startsWith('@')) atsign = atsign.replaceFirst('@', '');
      var answer = '';
      String? secondary;
      var ans = false;
      var prompt = false;
      var once = true;

      socket = await _socketFactory.createSocket(
          _rootDomain, '$_rootPort', SecureSocketConfig());
      _logger.finer('findSecondaryUrl: connection to root server established');
      // listen to the received data event stream
      socket.listen((List<int> event) async {
        _logger.finest('root socket listener received: $event');
        answer = utf8.decode(event);

        if (answer.endsWith('@') && prompt == false && once == true) {
          prompt = true;
          socket!.write('$atsign\n');
          await socket.flush();
          once = false;
        }

        if (answer.contains(':')) {
          answer = answer.replaceFirst('\r\n@', '');
          answer = answer.replaceFirst('@', '');
          answer = answer.replaceAll('@', '');
          secondary = answer.trim();
          ans = true;
        } else if (answer.startsWith('null')) {
          secondary = null;
          ans = true;
        }
      });
      // wait 30 seconds
      for (var i = 0; i < 6000; i++) {
        await Future.delayed(Duration(milliseconds: 5));
        if (ans) {
          response = secondary;
          socket.write('@exit\n');
          await socket.flush();
          socket.destroy();
          _logger.finer(
              'findSecondaryUrl got answer: $secondary and closing connection');
          return response;
        }
      }
      // .. and close the socket
      await socket.flush();
      socket.destroy();
      throw AtTimeoutException('AtLookup.findSecondary timed out');
    } on SocketException catch (se) {
      _logger.severe(
          '_findSecondary caught exception [$se] while connecting to root server url');
      throw RootServerConnectivityException(
          'Could not connect to Root Server at $_rootDomain:$_rootPort');
    } on Exception catch (exception) {
      _logger.severe('AtLookup.findSecondary connection to ' +
          _rootDomain +
          ' exception: ' +
          exception.toString());
      if (socket != null) {
        socket.destroy();
      }
      throw AtConnectException('AtLookup.findSecondary connection to ' +
          _rootDomain +
          ' exception: ' +
          exception.toString());
    } catch (error, stackTrace) {
      _logger.severe(
          'findSecondaryUrl: connection to root server failed with error: $error');
      _logger.severe(stackTrace);
      if (socket != null) {
        socket.destroy();
      }
      throw AtConnectException(
          'AtLookup.findSecondary connection to root server failed with error: $error');
    }
  }
}
