import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/verb_builder.dart';
import 'package:at_commons/src/verb/verb_util.dart';

/// Local lookup verb builder generates a command to lookup value of [atKey] stored in the secondary server.
/// e.g llookup key shared with alice
/// ```
/// // Lookup phone number available only to alice
///    var builder = LlookupVerbBuilder()..key=’@alice:phone’..atSign=’bob’;
/// ```
/// e.g llookup public key
/// ```
/// // Lookup email value that is available to everyone
///     var builder = LlookupVerbBuilder()..key=’public:email’..atSign=’bob’;
/// e.g llookup private key
/// // Lookup a credit card number that is accessible only by Bob
///    var builder = LlookupVerbBuilder()..key=’@bob:credit_card’..atSign=’bob’;
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
    if (isLocal) {
      command += 'local:';
    }
    if (isCached) {
      command += 'cached:';
    }
    if (isPublic) {
      command += 'public:';
    }
    if (sharedWith != null && sharedWith!.isNotEmpty) {
      command += '$sharedWith:';
    }
    command += atKey!;
    return '$command${VerbUtil.formatAtSign(sharedBy)}\n';
  }

  @override
  bool checkParams() {
    return atKey != null && sharedBy != null;
  }
}
