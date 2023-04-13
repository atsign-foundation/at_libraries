import 'dart:io';
import 'package:at_client/at_client.dart';
import 'package:path/path.dart' as path;

class HomeDirectoryUtil {

  static final homeDir = getHomeDirectory();

  static String? getHomeDirectory() {
    switch (Platform.operatingSystem) {
      case 'linux':
      case 'macos':
        return Platform.environment['HOME'];
      case 'windows':
        return Platform.environment['USERPROFILE'];
      case 'android':
        // Probably want internal storage.
        return '/storage/sdcard0';
      default:
        return null;
    }
  }

  static String getAtKeysPath(String atsign) {
     if(homeDir == null){
       throw AtClientException.message('Could not find home directory');
     }
     return path.join(homeDir!, '.atsign', 'keys', '${atsign}_key.atKeys');
  }

  static String getStorageDirectory(String atsign){
    if(homeDir == null){
      throw AtClientException.message('Could not find home directory');
    }
    return path.join(homeDir!, '.atsign', 'at_onboarding_cli', 'storage', atsign);
  }

  static String getCommitLogPath(String atsign){
    return path.join(getStorageDirectory(atsign), 'commitLog');
  }

  static String getHiveStoragePath(String atsign){
    return path.join(HomeDirectoryUtil.getStorageDirectory(atsign),'hive');
  }
}