import 'package:at_auth/at_auth.dart';
import 'package:at_commons/at_commons.dart';

/// Base class containing common attributes for enrollment requests either from first onboarding client with enrollment enabled
/// or a new client requesting enrollment.
@Deprecated('Use FirstEnrollmentRequest when onboarding an atSign and EnrollmentRequest to submit subsequent enrollment requests')
class AtEnrollmentRequest {
  final String? _appName;
  final String? _deviceName;
  final Map<String, String>? _namespaces;
  // ignore: prefer_final_fields
  EnrollOperationEnum _enrollOperationEnum = EnrollOperationEnum.request;

  final String? _enrollmentId;

  final String? _apkamPublicKey;

  String? get apkamPublicKey => _apkamPublicKey;

  String? get appName => _appName;

  String? get deviceName => _deviceName;

  Map<String, String>? get namespaces => _namespaces;

  EnrollOperationEnum get enrollOperationEnum => _enrollOperationEnum;

  String? get enrollmentId => _enrollmentId;

  final AtAuthKeys? _atAuthKeys;

  AtAuthKeys? get atAuthKeys => _atAuthKeys;

  AtEnrollmentRequest.builder(
      AtEnrollmentRequestBuilder atEnrollmentRequestBuilder)
      : _appName = atEnrollmentRequestBuilder._appName,
        _deviceName = atEnrollmentRequestBuilder._deviceName,
        _namespaces = atEnrollmentRequestBuilder._namespaces,
        _enrollOperationEnum =
            atEnrollmentRequestBuilder._enrollmentOperationEnum,
        _enrollmentId = atEnrollmentRequestBuilder._enrollmentId,
        _apkamPublicKey = atEnrollmentRequestBuilder._apkamPublicKey,
        _atAuthKeys = atEnrollmentRequestBuilder._atAuthKeys;

  /// Creates an [AtEnrollmentRequestBuilder] for building enrollment requests.
  ///
  /// Usage:
  ///
  ///```dart
  ///   AtEnrollmentRequestBuilder atEnrollmentRequestBuilder =
  ///         AtEnrollmentRequest.request()
  ///           ..setAppName('wavi')
  ///           ..setDeviceName('pixel')
  ///           ..setOtp('ABC123')
  ///           ..setNamespaces({'wavi': 'rw'}); // where "rw" represents
  ///                                               read-write permission
  ///```
  static AtEnrollmentRequestBuilder request() {
    AtEnrollmentRequestBuilder atEnrollmentRequestBuilder =
        AtEnrollmentRequestBuilder();
    atEnrollmentRequestBuilder._enrollmentOperationEnum =
        EnrollOperationEnum.request;
    return atEnrollmentRequestBuilder;
  }

  /// Creates an [AtEnrollmentRequestBuilder] for approval of enrollment requests.
  ///
  /// Usage:
  ///
  ///```dart
  ///   AtEnrollmentRequestBuilder atEnrollmentRequestBuilder =
  ///          AtEnrollmentRequest.approve()
  ///               ..setEnrollmentId('dummy-enrollment-id');
  ///               ..setEncryptedAPKAMSymmetricKey(dummy-encrypted-APKAM-Key)
  ///```
  static AtEnrollmentRequestBuilder approve() {
    AtEnrollmentRequestBuilder enrollmentBuilder = AtEnrollmentRequestBuilder();
    enrollmentBuilder._enrollmentOperationEnum = EnrollOperationEnum.approve;
    return enrollmentBuilder;
  }

  /// Creates an [AtEnrollmentRequestBuilder] for denial of enrollment requests.
  ///
  /// Usage:
  ///
  /// ```dart
  ///   AtEnrollmentRequestBuilder atEnrollmentRequestBuilder =
  ///          AtEnrollmentRequest.deny()
  ///               ..setEnrollmentId('dummy-enrollment-id');
  ///```
  static AtEnrollmentRequestBuilder deny() {
    AtEnrollmentRequestBuilder enrollmentBuilder = AtEnrollmentRequestBuilder();
    enrollmentBuilder._enrollmentOperationEnum = EnrollOperationEnum.deny;
    return enrollmentBuilder;
  }
}

// ignore: deprecated_member_use_from_same_package
/// Builder class for creating instances of [AtEnrollmentRequest].
class AtEnrollmentRequestBuilder {
  String? _appName;
  String? _deviceName;
  Map<String, String> _namespaces = {};
  EnrollOperationEnum _enrollmentOperationEnum = EnrollOperationEnum.request;
  String? _enrollmentId;
  String? _apkamPublicKey;
  AtAuthKeys? _atAuthKeys;

  AtEnrollmentRequestBuilder setAppName(String? appName) {
    _appName = appName;
    return this;
  }

  AtEnrollmentRequestBuilder setDeviceName(String? deviceName) {
    _deviceName = deviceName;
    return this;
  }

  AtEnrollmentRequestBuilder setNamespaces(Map<String, String> namespaces) {
    _namespaces = namespaces;
    return this;
  }

  AtEnrollmentRequestBuilder setEnrollmentId(String? enrollmentId) {
    _enrollmentId = enrollmentId;
    return this;
  }

  AtEnrollmentRequestBuilder setApkamPublicKey(String? apkamPublicKey) {
    _apkamPublicKey = apkamPublicKey;
    return this;
  }

  AtEnrollmentRequestBuilder setEnrollOperationEnum(
      EnrollOperationEnum enrollOperationEnum) {
    _enrollmentOperationEnum = enrollOperationEnum;
    return this;
  }

  AtEnrollmentRequestBuilder setAtAuthKeys(AtAuthKeys? atAuthKeys) {
    _atAuthKeys = atAuthKeys;
    return this;
  }

  // ignore: deprecated_member_use_from_same_package
  /// Builds and returns an instance of [AtEnrollmentRequest].
  // ignore: deprecated_member_use_from_same_package
  AtEnrollmentRequest build() {
    // ignore: deprecated_member_use_from_same_package
    return AtEnrollmentRequest.builder(this);
  }
}
