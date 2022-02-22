abstract class AtOnboardingService {
  ///perform initial one_time authentication
  ///to activate the atsign
  Future<bool> onboard();

  ///authenticate using privateKey
  Future<bool> authenticate();
}
