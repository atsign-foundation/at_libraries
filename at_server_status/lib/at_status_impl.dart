import 'dart:async';

import 'package:at_lookup/at_lookup.dart';

import 'at_server_status.dart';

class AtStatusImpl implements AtServerStatus {
  String? _rootUrl;
  int? _rootPort;

  String? get rootUrl => _rootUrl;

  set rootUrl(String? value) {
    value ??= 'root.atsign.org';
    _rootUrl = value;
  }

  int? get rootPort => _rootPort;

  set rootPort(int? value) {
    value ??= 64;
    _rootPort = value;
  }

  AtStatusImpl({String? rootUrl, int? rootPort}) {
    rootUrl ??= 'root.atsign.org';
    _rootUrl = rootUrl;
    rootPort ??= 64;
    _rootPort = rootPort;
  }

  @override
  Future<AtStatus> get(String atSign) async {
    atSign = atSign.startsWith('@') ? atSign : '@$atSign';
    // ignore: omit_local_variable_types
    AtStatus atStatus = AtStatus(atSign: atSign);
    atStatus.atSign = atSign;
    atStatus.rootStatus = RootStatus.notFound;
    // Check if @sign is in directory
    await _getRootStatus(atSign).then((AtStatus status) async {
      atStatus.rootStatus = status.rootStatus;
      atStatus.serverLocation = status.serverLocation;
      // If the @sign serverLocation is found in root, check the status of the @server
      if (atStatus.rootStatus == RootStatus.found &&
          atStatus.serverLocation != null &&
          atStatus.serverLocation!.isNotEmpty) {
        await _getServerStatus(atStatus.atSign, atStatus.serverLocation)
            .then((AtStatus status) async {
          atStatus.serverStatus = status.serverStatus;
        }).catchError((error) {
          atStatus.serverStatus = ServerStatus.unavailable;
        });
      }
    }).catchError((error) {
      atStatus.rootStatus = RootStatus.unavailable;
    });
    return atStatus;
  }

  @override
  Future<int> httpStatus(String atSign) async {
    // ignore: omit_local_variable_types
    AtStatus atStatus = await get(atSign);
    return atStatus.httpStatus();
  }

  Future<AtStatus> _getRootStatus(String atSign) async {
    // ignore: omit_local_variable_types
    AtStatus atStatus = AtStatus();
    atStatus.atSign = atSign;
    await CacheableSecondaryAddressFinder(rootUrl!, rootPort!)
            .findSecondary(atSign)
        .then((serverLocation) async {
      // enum RootStatus { running, stopped, unavailable, found, notFound }
      if (serverLocation.host.toString() != 'null' && serverLocation.host.isNotEmpty) {
        atStatus.rootStatus = RootStatus.found;
        atStatus.serverLocation = serverLocation.toString();
      } else {
        atStatus.rootStatus = RootStatus.notFound;
      }
    }).catchError((error) {
      atStatus.rootStatus = RootStatus.unavailable;
      print('_checkRootLocation error: $error');
    });
    return atStatus;
  }

  Future<AtStatus> _getServerStatus(
      String? atSign, String? serverLocation) async {
    // ignore: omit_local_variable_types
    AtStatus atStatus = AtStatus();
    var testKey = 'publickey$atSign';
    // ignore: omit_local_variable_types
    // enum ServerStatus { started, running, stopped, notFound, ready, activated, unavailable }
    if (serverLocation == null || serverLocation.isEmpty) {
      atStatus.rootStatus = RootStatus.notFound;
    } else {
      // ignore: omit_local_variable_types
      AtLookupImpl atLookupImpl =
          AtLookupImpl(atSign!, _rootUrl!, _rootPort!);
      await atLookupImpl.scan(auth: false).then((keysList) async {
        if (keysList.isNotEmpty) {
          if (keysList.contains(testKey)) {
            var value =
                await atLookupImpl.lookup('publickey', atSign, auth: false);
            value = value.replaceFirst('data:', '');
            if (value != 'null') {
              // @server has root location, is running and is activated
              atStatus.serverStatus = ServerStatus.activated;
            } else {
              // @server has root location, is started but not set up
              // @server has root location, is running and but not activated
              atStatus.serverStatus = ServerStatus.ready;
            }
          } else {
            // @server has root location, has started but not set up
            atStatus.serverStatus = ServerStatus.teapot;
          }
        } else {
          atStatus.serverStatus = ServerStatus.teapot;
        }
      }).catchError((error) async {
        // @server has root location, is not running and is not activated
        atStatus.serverStatus = ServerStatus.unavailable;
        print('_getServerStatus error: $error');
      }).whenComplete(() async => await atLookupImpl.close());
    }
    return atStatus;
  }
}
