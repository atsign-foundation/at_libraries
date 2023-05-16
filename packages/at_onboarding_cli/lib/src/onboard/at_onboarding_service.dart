import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'package:at_lookup/at_lookup.dart';

abstract class AtOnboardingService {
  ///perform initial one_time authentication to activate the atsign
  ///returns true if onboarded
  Future<bool> onboard();

  ///authenticate into secondary server using privateKey
  ///returns true if authenticated
  Future<bool> authenticate();

  ///returns an authenticated instance of AtClient
  @Deprecated('use getter')
  Future<AtClient?> getAtClient();

  // return true if atsign is onboarded and keys are persisted in local storage. false otherwise
  Future<bool> isOnboarded();

  ///returns authenticated instance of AtLookup
  @Deprecated('use getter')
  AtLookUp? getAtLookup();

  ///Closes the current instance of onboarding_service
  Future<void> close({int? exitCode});

  set atClient(AtClient? atClient);

  AtClient? get atClient;

  set atLookUp(AtLookUp? atLookUp);

  AtLookUp? get atLookUp;

  set atChops(AtChops? atChops);

  AtChops? get atChops;
}
