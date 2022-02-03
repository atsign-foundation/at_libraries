import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/auth_key_type.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_lookup/at_lookup.dart';

class OnboardingService {
  late String _decryptionKey;
  late String _atSign;
  var _secondaryConnection;
  late String _rootDomain;
  late int _rootPort;
  late String _pkamPrivateKey;

  AtSignLogger logger = AtSignLogger('Onboarding CLI');

  Future<bool> onboard() async {
    return true;
  }

  Future<dynamic> decryptKeys(String atSign, String jsonData) async {
    var jsonDecodedData = jsonDecode(jsonData);
    _decryptionKey = jsonDecodedData[AuthKeyType.SELF_ENCRYPTION_KEY_FROM_FILE]; var pkamPublicKey = EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PUBLIC_KEY_FROM_KEY_FILE],
        _decryptionKey);
    var pkamPrivateKey = EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PRIVATE_KEY_FROM_KEY_FILE],
        _decryptionKey);

    print(_decryptionKey);
  }

  Future<bool> authenticate(){
    AtLookupImpl atLookup = AtLookupImpl(_atSign, _rootDomain, _rootPort);
    atLookup.authenticate(_psamPrivateKey);

  }
}
