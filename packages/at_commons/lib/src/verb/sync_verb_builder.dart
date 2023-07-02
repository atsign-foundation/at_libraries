import 'package:at_commons/at_builders.dart';

class SyncVerbBuilder implements VerbBuilder {
  late int commitId;

  String? regex;

  int limit = 10;

  bool isPaginated = false;

  @override
  String buildCommand() {
    var command = 'sync:';
    if (isPaginated) {
      command += 'from:';
    }
    command += '$commitId';
    if (isPaginated) {
      command += ':limit:$limit';
    }
    if (regex != null && regex!.isNotEmpty) {
      command += ':$regex';
    }
    command += '\n';
    return command;
  }

  @override
  bool checkParams() {
    return true;
  }
}
