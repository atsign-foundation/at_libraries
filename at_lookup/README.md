<img src="https://atsign.dev/assets/img/@developersmall.png?sanitize=true">

### Now for a little internet optimism

# at_lookup library

## Overview:

The AtLookup Library is the low-level direct implementation of the @protocol verbs. The AtLookup package is an interface
to interact with the secondary server to execute commands(scan, update, lookup, llookup, plookup, etc).

## Get started:

### Installation:

To add this package as the dependency, add it to your pubspec.yaml

```dart  
dependencies:
  at_lookup: ^3.0.5
```

#### Add to your project

```sh
pub get 
```

#### Import in your application code

```dart
import 'package:at_lookup/at_lookup.dart';
```

### Clone it from github

Feel free to fork a copy of the source from the [GitHub Repo](https://github.com/atsign-foundation/at_libraries)

## Usage

### To get the instance of at_lookup

```dart
AtLookUp atLookUp = AtLookupImpl(
  '@alice',
  'root.atsign.com',
  64,
  privateKey: 'privateKey',
  cramSecret: 'cramSecret',
);
```
Please refer to [examples](example.dart) for more details.

## Open source usage and contributions

This is freely licensed open source code, so feel free to use it as is, suggest changes or enhancements or create your
own version. See CONTRIBUTING.md for detailed guidance on how to setup tools, tests and make a pull request.