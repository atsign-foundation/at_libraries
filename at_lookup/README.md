<img src="https://atsign.dev/assets/img/@developersmall.png?sanitize=true">

### Now for a little internet optimism

# at_lookup library
The AtLookup Library is the low-level direct implementation of the @protocol verbs

## Installation:
To use this library in your app, first add it to your pubspec.yaml
```  
dependencies:
  at_lookup: ^3.0.0
```
### Add to your project 
```
pub get 
```
### Import in your application code
```
import 'package:at_lookup/at_lookup.dart';
```
## Usage
```
var atLookUpImpl = AtLookupImpl(
    '@alice',
    'root.atsign.com',
    64,
    privateKey: 'privateKey',
    cramSecret: 'cramSecret',
  );

  var key = 'test_key';
  var sharedBy = '@alice';
  var sharedWith = '@bob';
  var result =
      await atLookUpImpl.update(key, 'test_value', sharedWith: sharedWith);
// lookup
  var lookup_result = await atLookUpImpl.lookup(key, sharedBy);
// plookup
  var plookup_result = await atLookUpImpl.plookup(key, sharedBy);
// llookup
  var llookup_result = await atLookUpImpl.llookup(key,
      sharedBy: sharedBy, sharedWith: sharedWith, isPublic: true);
// delete
  var delete_result =
      await atLookUpImpl.delete(key, sharedWith: '@bob', isPublic: false);
// scan
  var scan_result_list =
      await atLookUpImpl.scan(regex: '*', sharedBy: '@alice');
```