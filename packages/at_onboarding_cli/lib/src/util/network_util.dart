import 'package:at_utils/at_logger.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class NetworkUtil {

  static AtSignLogger logger = AtSignLogger('NetworkUtil');

  static Future<bool> isNetworkAvailable() async {
    var result = await InternetConnectionChecker().hasConnection;
    if (!result) {
      logger.finer('Unable to connect to internet');
    }
    return result;
  }
}
