import 'package:json_annotation/json_annotation.dart';
part 'enroll_params.g.dart';

@JsonSerializable()
class EnrollParams {
  String? enrollmentId;
  String? appName;
  String? deviceName;
  Map<String, String>? namespaces;
  String? otp;
  String? encryptedDefaultEncryptedPrivateKey;
  String? encryptedDefaultSelfEncryptionKey;
  String? encryptedAPKAMSymmetricKey;
  String? apkamPublicKey;
  EnrollParams();
  factory EnrollParams.fromJson(Map<String, dynamic> json) =>
      _$EnrollParamsFromJson(json);

  Map<String, dynamic> toJson() => _$EnrollParamsToJson(this);
}
