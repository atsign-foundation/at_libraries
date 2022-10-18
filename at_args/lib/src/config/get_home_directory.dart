import 'dart:io';

String? getHomeDirectory() {
  if(Platform.isMacOS || Platform.isLinux) return Platform.environment['HOME'];
  if(Platform.isWindows) return Platform.environment['USERPROFILE'];
  return null;
}

