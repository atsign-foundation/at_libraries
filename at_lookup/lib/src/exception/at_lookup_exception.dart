import 'package:at_commons/at_commons.dart';

class AtLookUpException implements Exception {
  String errorCode;
  String errorMessage;
  AtLookUpException(this.errorCode, this.errorMessage);
}

class AtLookUpExceptionUtil {
  static String getErrorCode(Exception exception) {
    var error_code = error_codes[exception.runtimeType.toString()];
    error_code ??= 'AT0014';
    return error_code;
  }

  static String getErrorDescription(String error_code) {
    return error_description[error_code];
  }
}
