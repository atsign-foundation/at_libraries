import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' show join;

import 'get_home_directory.dart';

export 'dart:io' show Directory;

class DotAtsign {
  static late final String _path;
  static final Completer<void> _initialized = Completer();

  factory DotAtsign() {
    if (!_initialized.isCompleted) {
      final home = getHomeDirectory();
      if (home == null) throw Exception('Home directory not found');

      _path = join(home, '.atsign');
      _initialized.complete();
    }
    return DotAtsign._();
  }

  const DotAtsign._();

  Directory get keys => Directory(join(_path, 'keys'));
  Directory get root => Directory(_path);
}
