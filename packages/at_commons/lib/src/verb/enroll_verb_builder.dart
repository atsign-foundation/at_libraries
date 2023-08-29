import 'dart:convert';

import 'package:at_commons/src/verb/abstract_verb_builder.dart';
import 'package:at_commons/src/verb/enroll_params.dart';
import 'package:meta/meta.dart';

import 'operation_enum.dart';

/// Enroll verb builder generates enroll verb command for APKAM(Application PKAM) authentication process.
class EnrollVerbBuilder extends AbstractVerbBuilder {
  String? enrollmentId;

  /// Operation type of the enroll verb - request/approve/deny. Default value will be request
  EnrollOperationEnum operation = EnrollOperationEnum.request;

  /// Name of the mobile application or client sending the enroll verb.
  String? appName;

  /// Name of the device sending the enroll verb.
  String? deviceName;

  /// Public key of an asymmetric key pair generated on the app or client.
  String? apkamPublicKey;

  /// otp for the enroll request. otp must be fetched from an already enrolled app.
  @experimental
  String? otp;

  Map<String, String>? namespaces;

  String? encryptedDefaultEncryptedPrivateKey;
  String? encryptedDefaultSelfEncryptionKey;
  String? encryptedAPKAMSymmetricKey;

  @override
  String buildCommand() {
    var sb = StringBuffer();
    sb.write('enroll:');
    sb.write(getEnrollOperation(operation));

    Map<String, dynamic> enrollParams = (EnrollParams()
          ..enrollmentId = enrollmentId
          ..appName = appName
          ..deviceName = deviceName
          ..apkamPublicKey = apkamPublicKey
          ..otp = otp
          ..namespaces = namespaces
          ..encryptedDefaultEncryptedPrivateKey =
              encryptedDefaultEncryptedPrivateKey
          ..encryptedDefaultSelfEncryptionKey =
              encryptedDefaultSelfEncryptionKey
          ..encryptedAPKAMSymmetricKey = encryptedAPKAMSymmetricKey)
        .toJson();
    enrollParams
        .removeWhere((key, value) => value == null || value.toString().isEmpty);
    if (enrollParams.isNotEmpty) {
      sb.write(':${jsonEncode(enrollParams)}');
    }
    sb.write('\n');
    return sb.toString();
  }

  @override
  bool checkParams() {
    return appName != null &&
        deviceName != null &&
        namespaces != null &&
        namespaces!.isNotEmpty &&
        otp != null &&
        apkamPublicKey != null;
  }
}
