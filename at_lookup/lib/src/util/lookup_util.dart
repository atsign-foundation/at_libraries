import 'package:at_commons/at_commons.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

/// LookUpUtil class
class LookUpUtil {
  /// Returns List contains domain and port
  static List<String> getSecondaryInfo(String url) {
    var result = <String>[];
    if (url.contains(':')) {
      var arr = url.split(':');
      result.add(arr[0]);
      result.add(arr[1]);
    }
    return result;
  }
}

class NetworkUtil {
  Future<bool> checkConnectivity() async {
    var result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      throw AtConnectException('Internet connection unavailable');
    }
    return result;
  }
}
