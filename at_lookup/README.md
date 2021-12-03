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

```dart
void main() async {
  var atLookUpImpl = AtLookupImpl(
    '@alice',
    'root.atsign.com',
    64,
    privateKey: 'privateKey',
    cramSecret: 'cramSecret',
  );

  /// To update a key into secondary server
  //Build update verb builder
  var updateVerbBuilder = UpdateVerbBuilder()
    ..atKey = 'phone'
    ..sharedBy = '@alice'
    ..sharedWith = '@bob'
    ..value = '+1 889 886 7879';

  // Sends update command to secondary server
  // Set sync attribute to true sync the value to secondary server.
  var updateResult = await atLookupImpl.executeVerb(updateVerbBuilder, sync: true);

  /// To lookup a value of a key sharedBy a specific atSign
  var lookupVerbBuilder = LookupVerbBuilder()
    ..atKey = 'phone'
    ..sharedBy = '@bob'
    ..auth = true;
  var lookupResult = await atLookupImpl.executeVerb(lookupVerbBuilder);

  /// To lookup a value of a public key
  var pLookupBuilder = PLookupVerbBuilder()
    ..atKey = 'lastName'
    ..sharedBy = '@bob';
  var pLookupResult = await atLookupImpl.executeVerb(pLookupBuilder);

  /// To retrieve the value of key created by self.
  var lLookupVerbBuilder = LLookupVerbBuilder()
    ..sharedWith = '@bob'
    ..atKey = 'phone'
    ..sharedBy = '@alice';
  var lLookupResult = await atLookupImpl.executeVerb(lLookupVerbBuilder);

  ///To remove a key from secondary server
  var deleteVerbBuilder = DeleteVerbBuilder()
    ..sharedWith = '@bob'
    ..atKey = 'phone'
    ..sharedBy = '@alice';
  var deleteResult = await atLookUpImpl.executeVerb(deleteVerbBuilder, sync: true);

  /// To retrieve keys from the secondary server
  var scanVerbBuilder = ScanVerbBuilder();
  var scanResult = await atLookUpImpl.executeVerb(scanVerbBuilder);

  ///To notify key to another atSign
  var notifyVerbBuilder = NotifyVerbBuilder()
    ..atKey = 'phone'
    ..sharedBy = '@alice'
    ..sharedWith = '@bob';
  var notifyResult = await atLookupImpl.executeVerb(notifyVerbBuilder);

  ///To retrieve the notifications received
  var notifyListVerbBuilder = NotifyListVerbBuilder();
  var notifyListResult = await atLookupImpl.executeVerb(notifyListVerbBuilder);
}
```

## Open source usage and contributions

This is freely licensed open source code, so feel free to use it as is, suggest changes or enhancements or create your
own version. See CONTRIBUTING.md for detailed guidance on how to setup tools, tests and make a pull request.