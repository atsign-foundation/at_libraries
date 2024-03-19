import 'dart:io';

import 'package:args/args.dart';

extension PrintAllArgParserUsage on ArgParser {
  static final String singleIndentation = '    ';

  printAllCommandsUsage(
      {String commandName = 'Usage:', IOSink? sink, int indent = 0}) {
    sink ??= stderr;

    // header message
    _writelnWithIndentation(sink, indent, commandName);

    // this parser usage
    List<String> usageLines = usage.split('\n');
    for (final l in usageLines) {
      _writelnWithIndentation(sink, indent + 1, l);
    }

    // sub-parsers usage
    for (final n in commands.keys) {
      commands[n]!.printAllCommandsUsage(
          commandName: n, sink: sink, indent: (indent + 1));
    }
  }

  _writelnWithIndentation(IOSink sink, int indent, String s) {
    for (int i = 0; i < indent; i++) {
      sink.write(singleIndentation);
    }
    sink.writeln(s);
  }
}
