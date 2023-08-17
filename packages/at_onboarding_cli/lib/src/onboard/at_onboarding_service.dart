import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';

abstract class AtOnboardingService {
  ///perform initial one_time authentication to activate the atsign
  ///returns true if onboarded
  Future<bool> onboard();

  ///Authenticate into secondary server using PKAM privateKey for legacy clients
  ///For clients that are enrolled through APKAM, pass the enrollmentId and auth is done using APKAM private key
  ///returns true if authenticated
  Future<bool> authenticate({String? enrollmentId});

  /// Sends an enroll request to the server. Apps that are already enrolled will receive notifications for this enroll request and can approve/deny the request
  /// appName - application name of the client e.g wavi,buzz, atmosphere etc.,
  /// deviceName - device identifier from the requesting application e.g iphone,any unique ID that identifies the requesting client
  /// totp - otp retrieved from an already enrolled app
  /// namespaces - key-value pair of namespace-access of the requesting client e.g {"wavi":"rw","contacts":"r"}
  Future<bool> enroll(String appName, String deviceName, String totp,
      Map<String, String> namespaces);

  ///returns an authenticated instance of AtClient
  @Deprecated('use getter')
  Future<AtClient?> getAtClient();

  // return true if atsign is onboarded and keys are persisted in local storage. false otherwise
  Future<bool> isOnboarded();

  ///returns authenticated instance of AtLookup
  @Deprecated('use getter')
  AtLookUp? getAtLookup();

  ///Closes the current instance of onboarding_service
  Future<void> close();

  set atClient(AtClient? atClient);

  AtClient? get atClient;

  set atLookUp(AtLookUp? atLookUp);

  AtLookUp? get atLookUp;

  set atChops(AtChops? atChops);

  AtChops? get atChops;
}
