import 'dart:io';
import 'package:at_utils/at_logger.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('A group of fixAtSign tests', () {
    test('Test file logging', () => testConsoleLogging());
  });
}

void deleteFile(filename) {
  var file = File(filename);
  if (file.existsSync()) {
    file.deleteSync();
  }
}

void testConsoleLogging() {
  var records = <LogRecord>[];
  var testLogger = AtSignLogger('test_console_logging');
  testLogger.logger.onRecord.listen(records.add);
  testLogger.info('hello');
  expect(records[0].message, 'hello');
}
