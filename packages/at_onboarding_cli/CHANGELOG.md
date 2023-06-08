## 1.2.7
- fix: upgraded at_client version to 3.0.60 to fix sync/monitor issue when using pkam private key from secure element.
- chore: upgraded at_commons to 3.0.47, at_utils to 3.0.13 and at_lookup to 3.0.37
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
