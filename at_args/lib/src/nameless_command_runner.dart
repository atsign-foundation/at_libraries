import 'package:args/command_runner.dart';

/// A [CommandRunner] with [executableName] set to the empty string
/// [invocation] and [usage] are reformatted to account for the empty [executableName]
class NamelessCommandRunner<T> extends CommandRunner<T> {
  NamelessCommandRunner(String description, {super.usageLineLength, super.suggestionDistanceLimit = 2})
      : super('', description);

  @override
  String get invocation => '<command> [arguments]';

  @override
  String get executableName => '';

  @override
  String get usage => super.usage.splitMapJoin(
        '"$executableName help',
        onMatch: (_) => '"help',
        onNonMatch: (m) => m,
      );
}
