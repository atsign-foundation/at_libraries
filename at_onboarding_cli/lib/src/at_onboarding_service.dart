import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/auth_key_type.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_lookup/at_lookup.dart';

class OnboardingService {
  late final String _rootDomain;
  late final int _rootPort;
  late String _decryptionKey;
  late String _atSign;
  late String _pkamPrivateKey;
  late String _pkamPublicKey;
  AtSignLogger logger = AtSignLogger('Onboarding CLI');

  OnboardingService(this._atSign, this._rootDomain, this._rootPort);
  Future<bool> onboard() async {
    return true;
  }

  void decryptKeys(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    _decryptionKey = jsonDecodedData[AuthKeyType.SELF_ENCRYPTION_KEY_FROM_FILE];
    _pkamPublicKey = EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PUBLIC_KEY_FROM_KEY_FILE],
        _decryptionKey);
    _pkamPrivateKey = EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PRIVATE_KEY_FROM_KEY_FILE],
        _decryptionKey);

    print(_decryptionKey);
  }

  Future<bool> authenticate() async {
    AtLookupImpl atLookup = AtLookupImpl(_atSign, _rootDomain, _rootPort);
    bool result = await atLookup.authenticate(_pkamPrivateKey);
    print(result);
    return result;
  }

  static Future<String?> findSecondary(
      String atsign, String? rootDomain, int rootPort) async {
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
      socket = await SecureSocket.connect(rootDomain, rootPort);
      // listen to the received data event stream
      socket.listen((List<int> event) async {
        answer = utf8.decode(event);
        print('event $event');
        print('anser $answer');

        if (answer.endsWith('@') && prompt == false && once == true) {
          prompt = true;
          socket!.write('$atsign\n');
          await socket.flush();
          once = false;
        }
        print('$event \n');


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
      throw Exception('AtLookup.findSecondary timed out');
    } on Exception catch (exception) {
      AtSignLogger('AtLookup').severe('AtLookup.findSecondary connection to ' +
          rootDomain! +
          ' exception: ' +
          exception.toString());
      if (socket != null) {
        socket.destroy();
      }
    } catch (error) {
      AtSignLogger('AtLookup').severe(
          'AtLookup.findSecondary connection to root server failed with error: $error');
      if (socket != null) {
        socket.destroy();
      }
    }
    return response;
  }
}
