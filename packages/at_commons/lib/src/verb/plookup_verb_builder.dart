import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/verb_builder.dart';
import 'package:at_commons/src/verb/verb_util.dart';

/// Plookup builder generates a command to lookup public value of [atKey] on secondary server of another atSign [sharedBy].
/// e.g If @alice has a public key e.g. public:phone@alice then use this builder to
/// lookup value of phone@alice from bob's secondary
/// ```
/// var builder = PlookupVerbBuilder()..key=’phone’..atSign=’alice’;
/// ```
class PLookupVerbBuilder implements VerbBuilder {
  /// Key of the [sharedBy] to lookup. [atKey] must have public access.
  String? atKey;

  /// atSign of the secondary server on which plookup has to be executed.
  String? sharedBy;

  String? operation;

  // if set to true, returns the value of key on the remote server instead of the cached copy
  bool bypassCache = false;

  @override
  String buildCommand() {
    String command = 'plookup:';
    if (bypassCache == true) {
      command += 'bypassCache:$bypassCache:';
    }
    if (operation != null) {
      command += '$operation:';
    }
    command += atKey!;
    return '$command${VerbUtil.formatAtSign(sharedBy)}\n';
  }

  @override
  bool checkParams() {
    return atKey != null && sharedBy != null;
  }
}
