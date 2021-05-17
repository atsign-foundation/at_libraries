//import 'dart:typed_data';

import 'package:at_client/at_client.dart';
import 'package:at_client/src/preference/at_client_preference.dart';
import 'at_demo_credentials.dart' as demo_data;
import 'package:at_commons/at_commons.dart';

class TestUtil {
  static AtClientPreference getPreferenceRemote() {
    var preference = AtClientPreference();
    preference.isLocalStoreRequired = false;
    preference.cramSecret = '<cram_secret>';
    preference.rootDomain = 'vip.ve.atsign.zone';
    preference.outboundConnectionTimeout = 60000;
    return preference;
  }

  static AtClientPreference getPreferenceLocal(
      String atsign, String namespace) {
    var preference = AtClientPreference();
    preference.hiveStoragePath = 'hive/client';
    preference.commitLogPath = 'hive/client/commit';
    preference.isLocalStoreRequired = true;
    preference.syncStrategy = SyncStrategy.IMMEDIATE;
    preference.privateKey = demo_data.pkamPrivateKeyMap[atsign];
    preference.rootDomain = 'vip.ve.atsign.zone';
    preference.namespace = namespace;
    return preference;
  }

  static Future<void> setEncryptionKeys(
      AtClientImpl atClient, String atsign) async {
    try {
      var metadata = Metadata();
      metadata.namespaceAware = false;
      var result;
      // set pkam private key
      result = await atClient
          .getLocalSecondary()
          .putValue(AT_PKAM_PRIVATE_KEY, demo_data.pkamPrivateKeyMap[atsign]);
      // set pkam public key
      result = await atClient
          .getLocalSecondary()
          .putValue(AT_PKAM_PUBLIC_KEY, demo_data.pkamPublicKeyMap[atsign]);
      // set encryption private key
      result = await atClient.getLocalSecondary().putValue(
          AT_ENCRYPTION_PRIVATE_KEY, demo_data.encryptionPrivateKeyMap[atsign]);
      //set aesKey
      result = await atClient
          .getLocalSecondary()
          .putValue(AT_ENCRYPTION_SELF_KEY, demo_data.aesKeyMap[atsign]);

      // set encryption public key. should be synced
      metadata.isPublic = true;
      var atKey = AtKey()
        ..key = 'publickey'
        ..metadata = metadata;
      result =
          await atClient.put(atKey, demo_data.encryptionPublicKeyMap[atsign]);
      print(result);
    } catch (e) {
      print('setting localKeys throws $e');
    }
  }

//  static List<int> _getKeyStoreSecret(String filePath) {
//    var hiveSecretString = File(filePath).readAsStringSync();
//    var secretAsUint8List = Uint8List.fromList(hiveSecretString.codeUnits);
//    return secretAsUint8List;
//  }
}
