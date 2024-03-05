<a href="https://atsign.com#gh-light-mode-only"><img width=250px src="https://atsign.com/wp-content/uploads/2022/05/atsign-logo-horizontal-color2022.svg#gh-light-mode-only" alt="The Atsign Foundation"></a><a href="https://atsign.com#gh-dark-mode-only"><img width=250px src="https://atsign.com/wp-content/uploads/2023/08/atsign-logo-horizontal-reverse2022-Color.svg#gh-dark-mode-only" alt="The Atsign Foundation"></a>

[![pub package](https://img.shields.io/pub/v/at_register)](https://pub.dev/packages/at_lookup) [![pub points](https://img.shields.io/pub/points/at_register?logo=dart)](https://pub.dev/packages/at_lookup/score) [![gitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](./LICENSE)

# at_register

## Overview:
This package contains code components that can interact with the AtRegistrar API and process the data received from the 
API.
This serves as a collection of code components
that can be consumed by other packages to fetch free atsigns and register them to emails.

Note:
If you're looking for a utility to get and activate a free atsign,
please feel free to take a look at `at_onboarding_cli/register_cli`
(or) any of the at_platforms apps available on PlayStore/AppStore

## Get started:

### Installation:

To add this package as the dependency, add it to your pubspec.yaml

```dart  
dependencies:
  at_register: ^1.0.0
```

#### Add to your project

```sh
dart pub get 
```

#### Import in your application code

```dart
import 'package:at_register/at_register.dart';
```

### Clone it from GitHub

Feel free to fork a copy of the source from the [GitHub Repo](https://github.com/atsign-foundation/at_libraries)

## Usage
### 0) Creating a RegisterParams object
```dart
RegisterParams params = RegisterParams()..email = 'email@email.com';
```

### 1) To fetch a free atsign

```dart
GetFreeAtsign getFreeAtsignTask = GetFreeAtsign(params);
RegisterTaskResult result = await getFreeAtsignTask.run();
print(result.data['atsign']);
```

### 2) To register the free atsign fetched in (1)

```dart
params.atsign = '@alice'; // preferably use the one fetched in (1)
RegisterAtsign registerAtsignTask = RegisterAtsign(params);
RegisterTaskResult result = await registerAtsignTask.run();
print(result.data['otpSent']); // contains true/false if verification code was delivered to email
```

### 3) To validate the verification code

```dart
params.otp = 'AB1C'; // to be fetched from user
ValidateOtp validateOtpTask = ValidateOtp(params);
RegisterTaskResult result = await validateOtp.run();
print(result.data['cram']);
```
Please refer to [examples](https://github.com/atsign-foundation/at_libraries/blob/doc_at_lookup/at_lookup/example/bin/example.dart) for more details.

## Open source usage and contributions

This is freely licensed open source code, so feel free to use it as is, suggest changes or enhancements or create your
own version. See CONTRIBUTING.md for detailed guidance on how to setup tools, tests and make a pull request.