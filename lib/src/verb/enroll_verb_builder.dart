import 'package:at_commons/src/verb/abstract_verb_builder.dart';

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

  List<String> namespaces = [];

  @override
  String buildCommand() {
    StringBuffer sb = StringBuffer();
    sb.write('enroll:');

    if (operation != null) {
      sb.write(getEnrollOperation(operation));
    }
    if (appName != null) {
      sb.write(':appName:$appName');
    }
    if (deviceName != null) {
      sb.write(':deviceName:$deviceName');
    }
    if (namespaces.isNotEmpty) {
      sb.write(':namespaces:${namespaces.join(';')}');
    }
    if (apkamPublicKey != null) {
      sb.write(':apkamPublicKey:$apkamPublicKey');
    }

    sb.write('\n');

    return sb.toString();
  }

  @override
  bool checkParams() {
    return appName != null &&
        deviceName != null &&
        namespaces.isNotEmpty &&
        apkamPublicKey != null;
  }
}
