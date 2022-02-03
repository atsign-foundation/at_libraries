import 'dart:convert';
import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
import 'package:at_onboarding_cli/src/auth_key_type.dart';
import 'package:at_utils/at_logger.dart';
import 'package:at_lookup/at_lookup.dart';

class OnboardingService {
  late final String _rootDomain;
  late final int _rootPort;
  late String _atSign;
  late final AtLookupImpl _atLookup =
      AtLookupImpl(_atSign, _rootDomain, _rootPort);
  AtSignLogger logger = AtSignLogger('Onboarding CLI');
  AtOnboardingConfig atOnboardingConfig = AtOnboardingConfig();

  OnboardingService(this._atSign) {
    _rootDomain = atOnboardingConfig.getRootServerDomain();
    _rootPort = atOnboardingConfig.getRootServerPort();
  }

  Future<bool> onboard() async {
    return true;
  }

  Future<String> _readAuthData(String atKeysFilePath) async {
    File atKeysFile = File(atKeysFilePath);
    String atAuthData = await atKeysFile.readAsString();
    return atAuthData;
  }

  String _getPkamPrivateKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    return EncryptionUtil.decryptValue(
        jsonDecodedData[AuthKeyType.PKAM_PRIVATE_KEY_FROM_KEY_FILE],
        _getDecryptionKey(jsonData));
  }

  String _getDecryptionKey(String jsonData) {
    var jsonDecodedData = jsonDecode(jsonData);
    var key = jsonDecodedData[AuthKeyType.SELF_ENCRYPTION_KEY_FROM_FILE];
    return key;
  }

  Future<bool> authenticate() async {
    String? filePath = atOnboardingConfig.getAtKeysFilePath();
    bool result = false;
    if (filePath != null) {
      String atAuthData = await _readAuthData(filePath);
      result = await _atLookup.authenticate(_getPkamPrivateKey(atAuthData));
      print(result);
    } else if (filePath == null) {
      logger.severe('AtKeysFile path is null');
    }
    return result;
  }

  AtLookupImpl getAtLookup() {
    return _atLookup;
  }
}
