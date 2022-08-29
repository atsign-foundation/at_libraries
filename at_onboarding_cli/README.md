<img width=250px src="https://atsign.dev/assets/img/atPlatform_logo_gray.svg?sanitize=true">

# at_onboarding_cli

## Introduction
at_onboarding_cli is a library to authenticate and onboard atSigns.

## Get Started

To add this package as the dependency in your pubspec.yaml

```dart  
dependencies:
  at_onboarding_cli: ^1.1.2
```
Getting Dependencies

```sh
dart pub get 
```

To import the library in your application code

```dart
import 'package:at_onboarding_cli/at_onboarding_cli.dart';
```

## Usage
Use cases for at_onboarding_cli:\
    1) Authentication\
    2) Onboarding (Activation)
    3) activate_cli
    
### Setting valid preferences:
   1) isLocalStorageRequired needs to be set to true as AtClient now needs a local secondary in order to work(for authentication only).
   2) As a result of Step 1, one also needs to provide commitLogPath and hiveStoragePath(for authentication only).
   3) One must set the namespace variable to match the name of their app.
   4) atKeysFile path should contain the file name.
   5) downloadPath should only contain name of the directory where the .atKeysFile is expected to be generated.

- Set `AtOnboardingPreference` to your preferred settings. These preferences will be used to configure the `AtOnboardingService`. 
    
 ```
  AtOnboardingPreference atOnboardingPreference = AtOnboardingPreference()
        ..rootDomain = 'root.atsign.org
        ..qrCodePath = 'storage/qr_code.png'
        ..hiveStoragePath = 'storage/hive'
        ..namespace = 'example'
        ..downloadPath = 'storage/files'
        ..isLocalStoreRequired = true
        ..commitLogPath = 'storage/commitLog'
        ..cramSecret = '<your cram secret>'
        ..privateKey = '<your private key here>'
        ..atKeysFilePath = 'storage/alice_key.atKeys';
 ```

### Authentication:
Proving that one actually owns the atSign. User needs to authenticate before performing operations on that atSign. Operations include reading, writing, deleting or updating data in the atsign's keystore and sending notifications from that atSign.

#### Steps to Authenticate
   1) Import at_onboarding_cli.
   2) Set preferences using AtOnboardingPreference. Either of secret key or path to .atKeysFile need to be provided to authenticate.
   3) Instantiate AtOnboardingServiceImpl using the required atSign and a valid instance of AtOnboardingPreference.
   4) Call the authenticate method on AtOnboardingService.
   5) Use getAtLookup/getAtClient to get authenticated instances of AtLookup and AtClient respectively which can be used to perform more complex operations on the atSign.
```
AtOnboardingService atOnboardingService = AtOnboardingServiceImpl('@alice', atOnboardingPreference);
atOnboardingService.authenticate();
AtClient? atClient = await atOnboardingService.getAtClient();
AtLookup? atLookup = atOnboardingService.getAtLookup();
```

### Onboarding: 
Performing initial one-time authentication using cram secret encoded in the qr_code. This process activates the atSign making it ready to use.

#### Steps to onboard:
   1) Import at_cli_onboarding.
   2) Set preferences using AtOnboardingPreference. Either of cram_secret or path to qr_code containing cram_secret need to be provided in order to activate the atSign.
   3) Setting the download path is mandatory in AtOnboardingPreference in order to save the .atKeysFile which contains necessary keys to authenticate.
   4) Instantiate AtOnboardingServiceImpl using the required atSign and a valid instance of AtOnboardingPreference.
   5) Call the onboard on AtOnboardingServiceImpl.
   6) Use getAtLookup to get authenticated instance of AtLookup (only) which can be used to perform more complex operations on the atSign.
 ```
AtOnboardingService atOnboardingService = AtOnboardingServiceImpl('@alice', atOnboardingPreference);
atOnboardingService.onboard();
AtLookup? atLookup = atOnboardingService.getAtLookup();
```

### activate_cli:
A simple tool to onboard(activate) an atSign through command-line arguments

#### Usage:
   1) Clone code from https://github.com/atsign-foundation/at_libraries
   2) Change directory to at_libraries/at_onboarding_cli in the cloned repository
   3) Run the following command
   4) You can find your .atKeysFile in directory at_onboarding_cli/keys
```
dart run bin/activate_cli.dart -a your_atsign -c your_cram_secret
```

Please refer to [example](https://pub.dev/packages/at_onboarding_cli/example) to better understand the usage.

## Open source usage and contributions

This is freely licensed open source code, so feel free to use it as is, suggest changes or enhancements or create your
own version. See CONTRIBUTING.md for detailed guidance on how to setup tools, tests and make a pull request.