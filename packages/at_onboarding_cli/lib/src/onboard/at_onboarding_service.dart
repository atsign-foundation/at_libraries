import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_auth/at_auth.dart';

abstract class AtOnboardingService {
  static const Duration defaultApkamRetryInterval = Duration(seconds: 10);

  /// Perform initial one_time authentication to activate the atsign
  /// returns true if successfully onboarded
  Future<bool> onboard();

  /// Authenticate into secondary server using PKAM privateKey for legacy clients
  ///
  /// For clients that are enrolled through APKAM, pass the enrollmentId and
  /// auth is done using APKAM private key
  ///
  /// Returns true if authentication is successful
  Future<bool> authenticate({String? enrollmentId});

  /// Sends an enroll request to the server, and waits for the request to be
  /// approved. Apps that are already enrolled will receive
  /// notifications for this enroll request and can approve/deny the request.
  /// If the request is denied, or times out, an exception will be thrown.
  ///
  /// Calling this method is exactly equivalent to calling
  /// [sendEnrollRequest], [awaitApproval] and [createAtKeysFile] in turn.
  ///
  /// [appName] - application name of the client e.g wavi,buzz, atmosphere etc.,
  /// [deviceName] - device identifier from the requesting application e.g iphone,any unique ID that identifies the requesting client
  /// [otp] - otp generated via an already enrolled app
  /// [namespaces] - key-value pair of namespace-access of the requesting client e.g {"wavi":"rw","contacts":"r"}
  /// [retryInterval] - how frequently to re-check if the request
  /// has been approved or denied.
  Future<AtEnrollmentResponse> enroll(
    String appName,
    String deviceName,
    String otp,
    Map<String, String> namespaces, {
    Duration retryInterval = defaultApkamRetryInterval,
  });

  /// Sends enrollment request. Application code may subsequently call
  /// [awaitApproval].
  Future<AtEnrollmentResponse> sendEnrollRequest(
    String appName,
    String deviceName,
    String otp,
    Map<String, String> namespaces,
  );

  /// Attempts PKAM auth until successful (i.e. request was approved).
  /// If the request was denied, or times out, then an exception is thrown.
  ///
  /// Once successful, the full set of keys are available in
  /// [enrollmentResponse].atAuthKeys
  Future<void> awaitApproval(
    AtEnrollmentResponse enrollmentResponse, {
    Duration retryInterval = defaultApkamRetryInterval,
    bool logProgress = true,
  });

  /// Create a file in the standardized format which apps may use to
  /// authenticate to an atServer.
  Future<File> createAtKeysFile(
    AtEnrollmentResponse er, {
    File? atKeysFile,
    bool allowOverwrite = false,
  });

  /// Returns an authenticated instance of AtClient
  @Deprecated('use getter')
  Future<AtClient?> getAtClient();

  // return true if atsign is onboarded and keys are persisted in local storage. false otherwise
  Future<bool> isOnboarded();

  /// Returns authenticated instance of AtLookup
  @Deprecated('use getter')
  AtLookUp? getAtLookup();

  /// Closes the current instance of onboarding_service
  Future<void> close({bool shouldExit = true, int exitCode = 0});

  set atClient(AtClient? atClient);

  AtClient? get atClient;

  set atLookUp(AtLookUp? atLookUp);

  AtLookUp? get atLookUp;

  set atChops(AtChops? atChops);

  AtChops? get atChops;

  set atAuth(AtAuth? atAuth);

  AtAuth? get atAuth;
}
