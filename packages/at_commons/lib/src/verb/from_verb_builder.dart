import 'dart:convert';

import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';

class FromVerbBuilder implements VerbBuilder {
  late String atSign;

  /// Stores the client configurations. Defaults to empty Map.
  Map<String, dynamic> clientConfig = {};

  @override
  String buildCommand() {
    var command = 'from:$atSign';
    if (clientConfig.isNotEmpty) {
      var clientConfigStr = jsonEncode(clientConfig);
      command += ':$CLIENT_CONFIG:$clientConfigStr';
    }
    command += '\n';
    return command;
  }

  @override
  bool checkParams() {
    return atSign.isNotEmpty;
  }
}
