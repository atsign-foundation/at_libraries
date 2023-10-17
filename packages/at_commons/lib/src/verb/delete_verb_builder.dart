import 'package:at_commons/at_commons.dart';
import 'package:at_commons/src/verb/abstract_verb_builder.dart';

/// Delete verb builder generates a command to delete a [atKey] from the secondary server.
/// ```
/// // @bob deleting a public phone key
///    var deleteBuilder = DeleteVerbBuilder()..key = 'public:phone@bob';
/// // @bob deleting the key “phone” shared with @alice
///    var deleteBuilder = DeleteVerbBuilder()..key = '@alice:phone@bob';
/// ```
class DeleteVerbBuilder extends AbstractVerbBuilder {
  /// The key to delete
  String? atKey;

  /// atSign of the secondary server on which llookup has to be executed.
  String? sharedBy;

  /// atSign of the secondary server for whom [atKey] is shared
  String? sharedWith;

  bool isPublic = false;

  bool isCached = false;

  /// Indicates if the key is local
  /// If the key is local, the key does not sync between cloud and local secondary
  bool isLocal = false;

  @override
  String buildCommand() {
    var command = 'delete:';
    command += '${buildKey()}\n';
    return command;
  }

  /// Returns a builder instance from a delete command
  static DeleteVerbBuilder getBuilder(String command) {
    var builder = DeleteVerbBuilder();
    var verbParams = VerbUtil.getVerbParam(VerbSyntax.delete, command)!;
    builder.atKey = verbParams[AtConstants.atKey];
    return builder;
  }

  @override
  bool checkParams() {
    return atKey != null;
  }

  String buildKey() {
    if (atKeyObj.key != null) {
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
