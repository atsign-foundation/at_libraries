import 'dart:io';

import 'package:at_client/at_client.dart';
import 'package:at_onboarding_cli/src/activate_cli/activate_cli.dart'
    as activate_cli;

Future<void> main(List<String> args) async {
  try {
    await activate_cli.main(args);
  } on IllegalArgumentException catch (e) {
    stderr.writeln('[Exception] Incorrect arguments provided\nCause: $e');
    exit(1);
  } on Exception catch (e) {
    stderr.writeln('[Exception] Aborting process with exit code:2\nCause: $e');
    exit(2);
  } on Error catch (e) {
    stderr.writeln('[Error] Aborting process with exit code:3\nCause: $e');
    exit(3);
  }
  // The onboarding_service_impl creates an AtClient instance which will start
  // the following services: SyncService, AtClientCommitLogCompaction,
  // Monitor connection in NotificationService.
  // We do not have an stop method in at_client that stop(s) the services, hence
  // to force quit, calling exit method.
  exit(0);
}
