import 'package:args/args.dart';

/// A class for taking a list of raw command line arguments and parsing out
/// options and flags from them.
class CommandLineParser {
  /// Parses [arguments], a list of command-line arguments, matches them against the
  /// flags and options defined by this parser, and returns the result.
  static var parser = ArgParser();

  static ArgResults? getParserResults(List<String> arguments) {
    ArgResults? results;
    // var parser = ArgParser();
    parser.addOption('email',
        abbr: 'e',
        help: 'The email address you would like to assign your atSign to');
    try {
      if (arguments.isNotEmpty) {
        results = parser.parse(arguments);
      }
      return results;
    } on ArgParserException {
      throw ArgParserException('ArgParserException\n${parser.usage}');
    }
  }

  static String getUsage() {
    return parser.usage;
  }
}
