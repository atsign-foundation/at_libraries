// ignore_for_file: non_constant_identifier_names

import 'package:at_utils/src/logging/handlers.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:logging/logging.dart' as logging;

/// Class for AtSignLogger Implementation
class AtSignLogger {
  late logging.Logger logger;
  static String _root_level = 'info';
  bool _hierarchicalLoggingEnabled = false;
  String? _level;

  static var loggingHandler = ConsoleLoggingHandler();

  AtSignLogger(String name) {
    logger = logging.Logger.detached(name);
    logger.onRecord.listen(loggingHandler);
    level = _root_level;
  }

  String? get level {
    return LogLevel.level.keys
        .firstWhereOrNull((k) => LogLevel.level[k].toString() == _level);
  }

  set level(String? value) {
    if (!_hierarchicalLoggingEnabled) {
      _hierarchicalLoggingEnabled = true;
      logging.hierarchicalLoggingEnabled = _hierarchicalLoggingEnabled;
    }
    _level = value;
    logger.level = LogLevel.level[_level!];
  }

  bool isLoggable(String value) => (LogLevel.level[value]! >= logger.level);

  // ignore: unnecessary_getters_setters
  bool get hierarchicalLoggingEnabled {
    return _hierarchicalLoggingEnabled;
  }

  set hierarchicalLoggingEnabled(bool value) {
    _hierarchicalLoggingEnabled = value;
  }

  static set root_level(String rootLevel) {
    _root_level = rootLevel.toLowerCase();
    logging.Logger.root.level = LogLevel.level[_root_level] ??
        logging.Level.INFO; // defaults to Level.INFO
  }

  static String get root_level {
    return _root_level;
  }

//  static set rootLogFilePath(String path) {
//    _rootLogFilePath = path;
//    if (_rootLogFilePath != null) {
//      logging.Logger.root.onRecord.listen(FileLoggingHandler(_rootLogFilePath));
//    }
//  }
//
//  void setLogFilePath(String path) {
//    logger.onRecord.listen(FileLoggingHandler(path));
//  }

//log methods
  void shout(message, [Object? error, StackTrace? stackTrace]) =>
      logger.shout(message, error, stackTrace);

  void severe(message, [Object? error, StackTrace? stackTrace]) =>
      logger.severe(message, error, stackTrace);

  void warning(message, [Object? error, StackTrace? stackTrace]) =>
      logger.warning(message, error, stackTrace);

  void info(message, [Object? error, StackTrace? stackTrace]) =>
      logger.info(message, error, stackTrace);

  void finer(message, [Object? error, StackTrace? stackTrace]) =>
      logger.finer(message, error, stackTrace);

  void finest(message, [Object? error, StackTrace? stackTrace]) =>
      logger.finest(message, error, stackTrace);
}

class LogLevel {
  static final Map<String, logging.Level> level = {
    'info': logging.Level.INFO,
    'shout': logging.Level.SHOUT,
    'severe': logging.Level.SEVERE,
    'warning': logging.Level.WARNING,
    'finer': logging.Level.FINER,
    'finest': logging.Level.FINEST,
    'all': logging.Level.ALL
  };
}
