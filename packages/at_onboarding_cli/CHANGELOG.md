## 1.6.2
- fix: `.atKeys` file was being generated in the wrong location in some cases
## 1.6.1
- feat: save enrollment details to local keystore
- build[deps]: upgrade at_auth to 2.0.5 | at_commons to 4.0.11
## 1.6.0
- feat: add 'status' command to the activate cli to check the status of an 
  atSign
## 1.5.0
- feat: 'activate' CLI is now APKAM-aware, and supports 
  - onboarding (as before)
  - submitting enrollment requests
  - listing / approving / denying / revoking enrollment requests
  - generating one-time passcodes
  - setting semi-permanent passcode
## 1.4.4
- feat: uptake changes for at_auth 2.0.0
- build[deps]: upgrade at_auth to 2.0.2 | at_lookup to 3.0.46 | at_client to 3.0.75 \
  at_commons to 4.0.5
## 1.4.3
- build[deps]: upgrade at_chops to 2.0.0 | at_lookup to 3.0.45 | at_client to 3.0.74
## 1.4.2
- build[deps]: upgrade: \
    at_commons to 4.0.0 | at_auth to 1.0.4 | at_chops to 1.0.7 | at_client to 3.0.73 \
    at_lookup to 3.0.44 | at_server_status to 1.0.4 | at_utils to 3.0.16
## 1.4.1
- feat: remove duplicate enrollment code and use at_auth
- chore: upgrade at_auth to 1.0.3, at_chops to 1.0.6, at_client to 3.0.69,at_lookup to 3.0.43
## 1.4.0
- feat: support for APKAM based authentication
- build: require at_client 3.0.65 or above
- build(deps): Upgrade at_client dependency to v3.0.67
- build(deps): Upgrade http dependency to v1.0.0
## 1.3.0
- feat: Introduced verification-code based activation of atsigns
- fix: deprecate qr_code based activation
- feat: introduced new exceptions
- fix: improve existing logger messages and added some
- fix: minor bug fixes
## 1.2.6
- feat: changes to integrate onboarding_cli with pkam secure element
- fix: issue with atKeys file creation while onboarding if the downloadPath directory does not exist
- fix: activate_cli throws exit(0) even though the process fails
- fix: onboarding_cli throws exception now when secondary address not found. Previously exit(1)
## 1.2.5
- feat: atkeys file now placed in standard location ~/.atsign/keys
## 1.2.4
- fix: Onboarding_cli throws exception when atsign does not start with '@'
- build: upgrade dependency at_utils to v3.0.12
- feat: Add atServiceFactory to AtOnboardingServiceImpl so that it can later be passed to AtClientManager.setCurrentAtSign 
## 1.2.3
- Enable use of AtChops
## 1.2.2
- Minor reformatting of user logs and minor bugfixes
- Fixed issue with using executables
- activate_cli can now be used with a qr_code instead of cram secret
- Removed option to use staging env in register_cli
- Upgrade dependency at_client to latest version v3.0.49
- Upgrade dependency at_lookup to latest version v3.0.33
- Upgrade dependency at_commons to latest version v3.0.32
## 1.2.1
- Introducing register_cli that fetches a free atsign and registers it to provided email
- fix: check to ensure secondary is created before trying to activate it
- Introducing binaries from register_cli and activate_cli
## 1.1.2
- Introducing activate_cli, a simple tool to activate atSigns from command-line
- Introducing a close() method to safely close the OnboardingService object
- Allow custom names for .atKeysFile when the file name is passed as atKeysFilePath during onboarding(activating)
- Removed at_client dependency in onboarding process flow
- correct example link replace @sign -> atSign
- Upgrade dependency at_client to latest version v3.0.38
- Upgrade dependency at_lookup to latest version v3.0.30
- Upgrade dependency at_utils to latest version v3.0.11
- Upgrade dependency at_commons to latest version v3.0.24
## 1.1.1
- Method to check and format atsign.
- Upgrade dependency at_client to latest version v3.0.32
## 1.1.0
- Fixed encryption public key with malformed syntax being synced to local secondary.
- [Breaking Change] Migrating AtException to AtClientException.
- Code refactoring and adjusting AtLogger log levels to differentiate important logs.
- Enforcing Strict data typing on method params and return types.
- Upgrade dependency at_client to latest version v3.0.31
- Upgrade dependency at_lookup to latest version v3.0.28
- Upgrade dependency at_commons to latest version v3.0.21
## 1.0.0
- Initial version.
