import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/cache/secondary_address_finder.dart';
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

class SecondaryUrlFinder {
  final String _rootDomain;
  final int _rootPort;
  SecondaryUrlFinder(this._rootDomain, this._rootPort);

  Future<String?> findSecondaryUrl(String atSign) async {
    return await _findSecondary(atSign);
  }

  Future<String?> _findSecondary(String atsign) async {
    String? response;
    SecureSocket? socket;
    try {
      AtSignLogger('AtLookup')
          .finer('AtLookup.findSecondary received atsign: $atsign');
      if (atsign.startsWith('@')) atsign = atsign.replaceFirst('@', '');
      var answer = '';
      String? secondary;
      var ans = false;
      var prompt = false;
      var once = true;
      // ignore: omit_local_variable_types
      socket = await SecureSocket.connect(_rootDomain, _rootPort);
      // listen to the received data event stream
      socket.listen((List<int> event) async {
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
          AtSignLogger('AtLookup').finer(
              'AtLookup.findSecondary got answer: $secondary and closing connection');
          return response;
        }
      }
      // .. and close the socket
      await socket.flush();
      socket.destroy();
      throw AtTimeoutException('AtLookup.findSecondary timed out');
    } on SocketException {
      throw RootServerConnectivityException(
          'Failed connecting to root server url $_rootDomain on port $_rootPort');
    } on Exception catch (exception) {
      AtSignLogger('AtLookup').severe('AtLookup.findSecondary connection to ' +
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
    } catch (error) {
      AtSignLogger('AtLookup').severe(
          'AtLookup.findSecondary connection to root server failed with error: $error');
      if (socket != null) {
        socket.destroy();
      }
      throw AtConnectException(
          'AtLookup.findSecondary connection to root server failed with error: $error');
    }
  }
}
