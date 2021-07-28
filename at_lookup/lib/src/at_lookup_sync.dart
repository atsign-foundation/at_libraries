import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_sync_message_listener.dart';
import 'package:at_lookup/src/util/lookup_util.dart';

class AtLookupSync extends AtLookupImpl {
  var _currentAtSign;
  var _rootDomain;
  var _rootPort;
  Function? syncCallback;

  AtLookupSync(
      String atSign,
      String rootDomain,
      int rootPort, {
        String? privateKey,
        String? cramSecret,
      }) : super(atSign, rootDomain, rootPort,
      privateKey: privateKey, cramSecret: cramSecret) {
    _currentAtSign = atSign;
    _rootDomain = rootDomain;
    _rootPort = rootPort;
  }

  @override
  Future<void> createConnection() async {
    if (!isConnectionAvailable()) {
      //1. find secondary url for atsign from lookup library
      var secondaryUrl = await AtLookupImpl.findSecondary(
          _currentAtSign, _rootDomain, _rootPort);
      if (secondaryUrl == null) {
        throw SecondaryNotFoundException('Secondary server not found');
      }
      var secondaryInfo = LookUpUtil.getSecondaryInfo(secondaryUrl);
      //2. create a connection to secondary server
      await createOutBoundConnection(
          secondaryInfo[0], secondaryInfo[1], _currentAtSign);
      //3. listen to server response
      messageListener = SyncMessageListener(connection);
      messageListener.syncCallback = syncCallback;
      messageListener.listen();
    }
  }

  @override
  // ignore: missing_return
  Future<String?> executeCommand(String atCommand, {bool auth = false}) async {
    if (auth) {
      if (privateKey != null) {
        await authenticate(privateKey);
      } else if (cramSecret != null) {
        await authenticate_cram(cramSecret);
      } else {
        throw UnAuthenticatedException(
            'Unable to perform atlookup auth. Private key/cram secret is not set');
      }
    }
    try {
       await connection!.write(atCommand);
    } on Exception catch (e) {
      logger.severe('Exception in sending to server, ${e.toString()}');
      rethrow;
    }
  }
}