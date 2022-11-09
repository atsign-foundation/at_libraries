import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/abstract_verb_builder.dart';

/// Local lookup verb builder generates a command to lookup value of [atKey] stored in the secondary server.
///
/// e.g llookup key shared with alice
///
/// * Lookup phone number available only to alice
///
/// * When sharedWith is populated, throws [InvalidAtKeyException] if isPublic or isLocal is set to true
///```dart
///    var builder = LLookupVerbBuilder()..sharedWith = '@alice'..key=’phone’..atSign=’bob’;
///```
///
/// e.g llookup public key
///
/// * Lookup email value that is available to everyone
///
/// * When isPublic is set to true, throws [InvalidAtKeyException] if isLocal is set to true or sharedWith is populated
///```dart
/// var builder = LLookupVerbBuilder()..key=’email’..atSign=’bob’..isPublic = true;
///```
/// e.g llookup private key
///
/// * Lookup a credit card number that is accessible only by Bob
///```
///    var builder = LLookupVerbBuilder()..sharedWith = '@bob'..key=’credit_card’..atSign=’bob’;
///```
///
/// e.g. llookup a local key
/// * Lookup a local key that is accessible only by bob
///
/// * When isLocal is set to true, throws [InvalidAtKeyException] if isPublic or isCached is set true or sharedWith is populated
///```dart
///    var builder = LLookupVerbBuilder()..key = 'password'..sharedBy = '@bob'..isLocal = true;
///```
///
/// e.g. llookup a cached key
/// * Lookup a cached key that shared by alice to bob
///
/// * When isCached is set to true, throws [InvalidAtKeyException] if isLocal is set to true
///
///```dart
/// var builder = LLookupVerbBuilder()
///               ..isCached = true
///               ..sharedWith = '@bob'
///               ..key = 'phone'
///               ..sharedBy = '@alice'
///```
///
/// e.g. llookup a cached public key
/// * Lookup a cached key that is public key of alice
///```dart
/// var builder = LLookupVerbBuilder()
///               ..isCached = true
///               ..isPublic = true
///               ..key = 'aboutMe'
///               ..sharedBy = '@alice'
///```
class LLookupVerbBuilder extends AbstractVerbBuilder {
  /// the key of [atKey] to llookup. [atKey] can have either public, private or shared access.
  String? atKey;

  /// atSign of the secondary server on which llookup has to be executed.
  String? sharedBy;

  /// atSign of the secondary server for whom [atKey] is shared
  String? sharedWith;

  bool isPublic = false;

  bool isCached = false;

  String? operation;

  /// Indicates if the key is local
  /// If the key is local, the key does not sync between cloud and local secondary
  bool isLocal = false;

  @override
  String buildCommand() {
    var command = 'llookup:';
    if (operation != null) {
      command += '$operation:';
    }
    return command += '${buildKey()}\n';
  }

  @override
  bool checkParams() {
    return atKey != null && sharedBy != null;
  }

  String buildKey() {
    if(atKeyObj.key != null){
      return atKeyObj.toString();
    }
    super.atKeyObj
      ..key = atKey
      ..sharedBy = sharedBy
      ..sharedWith = sharedWith
      ..isLocal = isLocal
      ..metadata = (Metadata()
        ..isPublic = isPublic
        ..isCached = isCached);
    // validates the data in the verb builder.
    // If validation is successful, build and return the key;
    // else throws exception.
    validateKey();
    return super.atKeyObj.toString();
  }
}
