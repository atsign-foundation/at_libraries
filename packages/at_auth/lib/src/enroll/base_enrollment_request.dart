import 'package:at_commons/at_commons.dart';

/// The BaseEnrollmentRequest class encapsulates shared fields between the InitialEnrollmentRequest and EnrollmentRequest.
///
/// The [InitialEnrollmentRequest] is used when the app is onboarded for the first time. The request is sent to the server
/// via the CRAM authenticated connection and is auto approved.
///
/// The [EnrollmentRequest] is used by the other apps to authenticate. This enrollment request is send to the server and is
/// notified to the apps which has access to "__manage" namespace. If the request is approved, then the requesting app is
/// authenticated and authorized to access the namespaces specified in the request; otherwise, the requesting app is prevented
/// from log-in.
abstract class BaseEnrollmentRequest {
  String appName;
  String deviceName;
  final EnrollOperationEnum enrollOperation = EnrollOperationEnum.request;
  String? apkamPublicKey;

  BaseEnrollmentRequest(
      {required this.appName, required this.deviceName, this.apkamPublicKey});
}
