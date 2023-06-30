import 'package:at_commons/src/verb/abstract_verb_builder.dart';
import 'package:meta/meta.dart';

import 'operation_enum.dart';

/// Enroll verb builder generates enroll verb command for APKAM(Application PKAM) authentication process.
class EnrollVerbBuilder extends AbstractVerbBuilder {
  /// Operation type of the enroll verb - request/approve/deny. Default value will be request
  EnrollOperationEnum operation = EnrollOperationEnum.request;

  /// Name of the mobile application or client sending the enroll verb.
  String? appName;

  /// Name of the device sending the enroll verb.
  String? deviceName;

  /// Public key of an asymmetric key pair generated on the app or client.
  String? apkamPublicKey;

  /// totp for the enroll request. totp must be fetched from an already enrolled app.
  @experimental
  int? totp;

  List<String> namespaces = [];

  @override
  String buildCommand() {
    var sb = StringBuffer();
    sb.write('enroll:');

    sb.write(getEnrollOperation(operation));

    sb.write(_getValueWithParamName('appName', appName));
    sb.write(_getValueWithParamName('deviceName', deviceName));
    if (namespaces.isNotEmpty) {
      sb.write(':namespaces:[${namespaces.join(';')}]');
    }
    sb.write(_getValueWithParamName('totp', totp.toString()));
    sb.write(_getValueWithParamName('apkamPublicKey', apkamPublicKey));

    sb.write('\n');

    return sb.toString();
  }

  String _getValueWithParamName(String paramName, String? paramValue) {
    if (paramValue != null && paramValue.isNotEmpty && paramValue != 'null') {
      return ':$paramName:$paramValue';
    }
    return '';
  }

  @override
  bool checkParams() {
    return appName != null &&
        deviceName != null &&
        namespaces.isNotEmpty &&
        totp != null &&
        apkamPublicKey != null;
  }
}
