import 'package:at_auth/src/onboard/at_onboarding_request.dart';
import 'package:at_auth/src/onboard/at_onboarding_response.dart';
import 'package:at_auth/src/request/at_auth_request.dart';
import 'package:at_auth/src/response/at_auth_response.dart';
import 'package:at_chops/at_chops.dart';

abstract class AtAuth {
  AtChops? atChops;

  /// Authenticate method is called after an atsign has been onboarded or user has the atKeys file through a prior onboarding
  /// Step 1. Check if the atsign is onboarded
  /// Step 1.1 do a pkam authentication
  /// Step 2. If atsign is not onboarded, read the atkeys data
  /// Step 2.1 decrypt the keys from atkeys file data
  /// Step 2.2 Persist the keys to keychain
  /// Step 2.3 Create an atChops instance if not set by the caller
  /// Step 2.4 Initialize at_client instance
  /// Step 2.5 Persist keys to local secondary
  /// Step 2.6 Perform pkam authenticate through at_client instance
  /// Set the client preferences in [atAuthRequest.preference]
  /// AtKeys file data has to be set in [atAuthRequest.atKeysData] if the user has already onboarded
  /// Set [atAuthRequest.publicKeyId] if pkam auth mode is [PkamAuthMode.sim]
  Future<AtAuthResponse> authenticate(AtAuthRequest atAuthRequest);

  /// Check whether an atSign is already onboarded
  /// If an atsign is already onboarded then key pairs/symmetric keys should be available in local keystore.
  /// Returns true if pkam public key, default encryption keypair, self encryption key are available in local keystore.
  /// Returns false if any of the above keys are not present.
  Future<bool> isOnboarded({String? atSign});

  /// Onboard method is called when an atsign is activated for the first time in an app.
  /// Step 1. perform cram auth
  /// Step 2. generate pkam key pair (if pkam auth mode is [PkamAuthMode.keysFile])
  /// Step 3. read public key from secure element (if pkam auth mode is [PkamAuthMode.sim]) or use pkam public key from Step 2 and update to secondary server
  /// Step 4. perform pkam auth
  /// Step 5. Generate encryption keypair and self encryption key
  /// Step 6. Save key data to keychain and local secondary
  /// Step 7. delete cram secret from secondary server
  /// Set [atOnboardingRequest.publicKeyId] if pkam auth mode is [PkamAuthMode.sim]
  /// Set the AtClient preferences in [atOnboardingRequest.preference]
  Future<AtOnboardingResponse> onboard(
      AtOnboardingRequest atOnboardingRequest, String cramSecret);
}
