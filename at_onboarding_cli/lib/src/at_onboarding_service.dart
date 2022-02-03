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
}
