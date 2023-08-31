// GENERATED CODE - DO NOT MODIFY BY HAND
// dart run build_runner build to generate this file

part of 'enroll_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollParams _$EnrollParamsFromJson(Map<String, dynamic> json) => EnrollParams()
  ..enrollmentId = json['enrollmentId'] as String?
  ..appName = json['appName'] as String?
  ..deviceName = json['deviceName'] as String?
  ..namespaces = (json['namespaces'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  )
  ..otp = json['otp'] as String?
  ..encryptedDefaultEncryptedPrivateKey =
      json['encryptedDefaultEncryptedPrivateKey'] as String?
  ..encryptedDefaultSelfEncryptionKey =
      json['encryptedDefaultSelfEncryptionKey'] as String?
  ..encryptedAPKAMSymmetricKey = json['encryptedAPKAMSymmetricKey'] as String?
  ..apkamPublicKey = json['apkamPublicKey'] as String?;

Map<String, dynamic> _$EnrollParamsToJson(EnrollParams instance) =>
    <String, dynamic>{
      'enrollmentId': instance.enrollmentId,
      'appName': instance.appName,
      'deviceName': instance.deviceName,
      'namespaces': instance.namespaces,
      'otp': instance.otp,
      'encryptedDefaultEncryptedPrivateKey':
          instance.encryptedDefaultEncryptedPrivateKey,
      'encryptedDefaultSelfEncryptionKey':
          instance.encryptedDefaultSelfEncryptionKey,
      'encryptedAPKAMSymmetricKey': instance.encryptedAPKAMSymmetricKey,
      'apkamPublicKey': instance.apkamPublicKey,
    };
