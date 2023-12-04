import 'package:at_commons/at_commons.dart';

/// Represents an enrollment request for APKAM.
class AtEnrollmentRequest {
  final String? _appName;
  final String? _deviceName;
  final String? _otp;
  final Map<String, String>? _namespaces;
  final EnrollOperationEnum _enrollOperationEnum;

  final String? _enrollmentId;
  final String? _apkamPublicKey;
  final String? _encryptedAPKAMSymmetricKey;

  final String? _encryptedDefaultEncryptionPrivateKey;
  final String? _encryptedDefaultSelfEncryptionKey;
  String? get appName => _appName;

  String? get deviceName => _deviceName;

  String? get otp => _otp;

  Map<String, String>? get namespaces => _namespaces;

  EnrollOperationEnum get enrollOperationEnum => _enrollOperationEnum;

  String? get enrollmentId => _enrollmentId;

  String? get encryptedAPKAMSymmetricKey => _encryptedAPKAMSymmetricKey;

  String? get encryptedDefaultEncryptionPrivateKey =>
      _encryptedDefaultEncryptionPrivateKey;

  String? get encryptedDefaultSelfEncryptionKey =>
      _encryptedDefaultSelfEncryptionKey;

  String? get apkamPublicKey => _apkamPublicKey;

  AtEnrollmentRequest._builder(
      AtEnrollmentRequestBuilder atEnrollmentRequestBuilder)
      : _appName = atEnrollmentRequestBuilder._appName,
        _deviceName = atEnrollmentRequestBuilder._deviceName,
        _namespaces = atEnrollmentRequestBuilder._namespaces,
        _otp = atEnrollmentRequestBuilder._otp,
        _enrollOperationEnum =
            atEnrollmentRequestBuilder._enrollmentOperationEnum,
        _enrollmentId = atEnrollmentRequestBuilder._enrollmentId,
        _encryptedAPKAMSymmetricKey =
            atEnrollmentRequestBuilder._encryptedAPKAMSymmetricKey,
        _encryptedDefaultEncryptionPrivateKey =
            atEnrollmentRequestBuilder._encryptedDefaultEncryptionPrivateKey,
        _encryptedDefaultSelfEncryptionKey =
            atEnrollmentRequestBuilder._encryptedDefaultSelfEncryptionKey,
        _apkamPublicKey = atEnrollmentRequestBuilder._apkamPublicKey;

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

/// Builder class for creating instances of [AtEnrollmentRequest].
class AtEnrollmentRequestBuilder {
  String? _appName;
  String? _deviceName;
  Map<String, String> _namespaces = {};
  String? _otp;
  late EnrollOperationEnum _enrollmentOperationEnum;
  String? _enrollmentId;
  String? _encryptedAPKAMSymmetricKey;
  String? _encryptedDefaultEncryptionPrivateKey;
  String? _encryptedDefaultSelfEncryptionKey;
  String? _apkamPublicKey;

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

  AtEnrollmentRequestBuilder setOtp(String? otp) {
    _otp = otp;
    return this;
  }

  AtEnrollmentRequestBuilder setEnrollmentId(String? enrollmentId) {
    _enrollmentId = enrollmentId;
    return this;
  }

  AtEnrollmentRequestBuilder setEncryptedAPKAMSymmetricKey(
      String? encryptedAPKAMSymmetricKey) {
    _encryptedAPKAMSymmetricKey = encryptedAPKAMSymmetricKey;
    return this;
  }

  AtEnrollmentRequestBuilder setEncryptedDefaultEncryptionPrivateKey(
      String? encryptedDefaultEncryptionPrivateKey) {
    _encryptedDefaultEncryptionPrivateKey =
        encryptedDefaultEncryptionPrivateKey;
    return this;
  }

  AtEnrollmentRequestBuilder setEncryptedDefaultSelfEncryptionKey(
      String? encryptedDefaultSelfEncryptionKey) {
    _encryptedDefaultSelfEncryptionKey = encryptedDefaultSelfEncryptionKey;
    return this;
  }

  AtEnrollmentRequestBuilder setApkamPublicKey(String? apkamPublicKey) {
    _apkamPublicKey = apkamPublicKey;
    return this;
  }

  /// Builds and returns an instance of [AtEnrollmentRequest].
  AtEnrollmentRequest build() {
    return AtEnrollmentRequest._builder(this);
  }
}
