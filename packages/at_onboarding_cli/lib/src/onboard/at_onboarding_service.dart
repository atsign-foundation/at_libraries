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

  ///returns authenticated instance of AtLookup
  @Deprecated('use getter')
  AtLookUp? getAtLookup();

  ///kills the current instance of onboarding_service
  Future<void> close();

  set atClient(AtClient? atClient);

  AtClient? get atClient;

  set atLookUp(AtLookUp? atLookUp);

  AtLookUp? get atLookUp;
}
