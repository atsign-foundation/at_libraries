import 'package:at_commons/at_builders.dart';
import 'package:at_lookup/at_lookup.dart';

/// The example below demonstrate on how to use at_lookup package to interact with secondary server
/// to execute the verbs.
/// NOTE: Running this example would result in an exception. The At_lookup package would require
/// a secondary running.
void main() async {
  var atLookupImpl = AtLookupImpl(
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

  var updateResult =
      await atLookupImpl.executeVerb(updateVerbBuilder, sync: true);

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
  var deleteResult =
      await atLookupImpl.executeVerb(deleteVerbBuilder, sync: true);

  /// To retrieve keys from the secondary server
  var scanVerbBuilder = ScanVerbBuilder();
  var scanResult = await atLookupImpl.executeVerb(scanVerbBuilder);

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
