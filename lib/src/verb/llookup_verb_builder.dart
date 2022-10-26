import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/utils/string_utils.dart';
import 'package:at_commons/src/verb/verb_builder.dart';

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
class LLookupVerbBuilder implements VerbBuilder {
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

  /// Validates the verb builder data and returns the string representation of [AtKey]
  /// Throws [InvalidAtKeyException] if the validation fails
  String buildKey() {
    // validates the key. Throw InvalidAtKeyException if validation fails
    _validateKey();
    // Builds key if validation is successful.
    String key = '';
    if (isCached == true) {
      key = 'cached:';
    }
    if (isLocal == true) {
      key = 'local:';
    } else if (isPublic == true) {
      key += 'public:';
    } else if (sharedWith.isNotNull) {
      key += '${VerbUtil.formatAtSign(sharedWith)}:';
    }
    key += '${atKey!}${VerbUtil.formatAtSign(sharedBy)}';

    return key;
  }

  /// Validates the [AtKey]
  /// Throws [InvalidAtKeyException] if the validation fails
  void _validateKey() {
    if (isCached == true && isLocal == true) {
      throw InvalidAtKeyException('Cached key cannot be a local key');
    }
    if (isLocal == true && (isPublic == true || sharedWith.isNotNull)) {
      throw InvalidAtKeyException(
          'When isLocal is set to true, cannot set isPublic and sharedWith');
    }
    if (isPublic == true && sharedWith.isNotNull) {
      throw InvalidAtKeyException(
          'When isPublic is set to true, sharedWith cannot be populated');
    }
    if (atKey.isNull) {
      throw InvalidAtKeyException('Key cannot be null or empty');
    }
  }

  @override
  bool checkParams() {
    return atKey != null && sharedBy != null;
  }
}
