import 'package:at_commons/at_commons.dart';

/// AtLookUpException class
class AtLookUpException implements Exception {
  String? errorCode;
  String? errorMessage;
  AtLookUpException(this.errorCode, this.errorMessage);
}

/// AtLookUpExceptionUtil to get ErrorCode and ErrorDescription
class AtLookUpExceptionUtil {
  /// Returns ErrorCode String
  static String getErrorCode(Exception exception) {
    var error_code = error_codes[exception.runtimeType.toString()];
    error_code ??= 'AT0014';
    return error_code;
  }

  /// Returns ErrorDescription String
  static String? getErrorDescription(String error_code) {
    return error_description[error_code];
  }
}
