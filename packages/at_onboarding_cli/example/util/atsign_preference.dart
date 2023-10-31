import 'dart:convert';
import 'dart:typed_data';
import 'package:at_client/src/preference/at_client_preference.dart';
import 'package:at_onboarding_cli/src/util/home_directory_util.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';

class AtSignPreference {
  static AtClientPreference getAlicePreference(
      String atSign, String enrollmentId) {
    var preference = AtClientPreference();
    preference.hiveStoragePath = HomeDirectoryUtil.getHiveStoragePath(atSign,
        enrollmentId: enrollmentId);
    preference.commitLogPath =
        HomeDirectoryUtil.getCommitLogPath(atSign, enrollmentId: enrollmentId);
    preference.isLocalStoreRequired = true;
    preference.rootDomain = 'vip.ve.atsign.zone';
    var hashFile = _getShaForAtSign(atSign);
    preference.keyStoreSecret =
        _getKeyStoreSecret('${preference.hiveStoragePath}/$hashFile.hash');
    return preference;
  }

  static List<int> _getKeyStoreSecret(String filePath) {
    var hiveSecretString = File(filePath).readAsStringSync();
    var secretAsUint8List = Uint8List.fromList(hiveSecretString.codeUnits);
    return secretAsUint8List;
  }

  static String _getShaForAtSign(String atsign) {
    var bytes = utf8.encode(atsign);
    return sha256.convert(bytes).toString();
  }
}
