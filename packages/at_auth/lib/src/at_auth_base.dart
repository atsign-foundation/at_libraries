import 'package:at_auth/src/onboard/at_onboarding_request.dart';
import 'package:at_auth/src/onboard/at_onboarding_response.dart';
import 'package:at_auth/src/auth/at_auth_request.dart';
import 'package:at_auth/src/auth/at_auth_response.dart';
import 'package:at_chops/at_chops.dart';

/// Interface for onboarding and authentication to a secondary server of an atsign
abstract class AtAuth {
  AtChops? atChops;

  /// Authenticate method is invoked when an atsign wants to authenticate to secondary server with an .atKeys file
  /// Step 1. Read the keys from [atAuthRequest.atAuthKeys] or [atAuthRequest.atKeysFilePath]
  /// Step 2  Perform pkam authentication
  Future<AtAuthResponse> authenticate(AtAuthRequest atAuthRequest);

  /// Onboard method is invoked when an atsign is activated for the first time from a client app.
  /// Step 1. Perform cram auth
  /// Step 2. Generate pkam, encryption keypairs and apkam symmetric key
  /// Step 3. Update pkam public key to secondary
  /// Step 4. Perform pkam auth
  /// Step 5. Update encryption public key to server and delete cram secret from server
  /// Set [atOnboardingRequest.publicKeyId] if pkam auth mode is [PkamAuthMode.sim]
  Future<AtOnboardingResponse> onboard(
      AtOnboardingRequest atOnboardingRequest, String cramSecret);
}
