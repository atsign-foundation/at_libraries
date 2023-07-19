import 'dart:io';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';

/// scan_example.dart
///
/// <br/>
/// Create an atClient and list the identifiers of all the records stored
/// in its atServer
Future<void> main(List<String> args) async {
  try {
    AtClient atClient = (await CLIBase.fromCommandLineArgs(args)).atClient;
    var allDataKeys = await atClient.getRemoteSecondary()!.executeCommand('scan\n');
    print(allDataKeys);
    exit(0);
  } catch (e) {
    print (e);
    print (CLIBase.argsParser.usage);
  }
}