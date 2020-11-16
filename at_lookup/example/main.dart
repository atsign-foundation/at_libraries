import 'package:at_lookup/at_lookup.dart';

void main(List<String> arguments) async {
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
  //update
  print(await atLookUpImpl.update(key, 'test_value', sharedWith: sharedWith));
// lookup
  print(await atLookUpImpl.lookup(key, sharedBy));
// plookup
  print(await atLookUpImpl.plookup(key, sharedBy));
// llookup
  print(await atLookUpImpl.llookup(key,
      sharedBy: sharedBy, sharedWith: sharedWith, isPublic: true));
// delete
  print(await atLookUpImpl.delete(key, sharedWith: '@bob', isPublic: false));
// scan
  print(await atLookUpImpl.scan(regex: '*', sharedBy: '@alice'));
}
