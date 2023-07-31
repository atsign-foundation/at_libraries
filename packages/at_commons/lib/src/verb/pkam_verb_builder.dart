import 'package:at_commons/at_builders.dart';

class PkamVerbBuilder implements VerbBuilder {
  /// Enrollment approvalId generated by server for APKAM
  String? enrollmentlId;

  String? signingAlgo;

  String? hashingAlgo;

  /// base64encoded signed challenge
  late String signature;

  @override
  String buildCommand() {
    var command = 'pkam';
    if (signingAlgo != null && signingAlgo!.isNotEmpty) {
      command += ':signingAlgo:$signingAlgo';
    }
    if (hashingAlgo != null && hashingAlgo!.isNotEmpty) {
      command += ':hashingAlgo:$hashingAlgo';
    }
    if (enrollmentlId != null && enrollmentlId!.isNotEmpty) {
      command += ':enrollmentId:$enrollmentlId';
    }
    command += ':$signature';
    command += '\n';
    return command;
  }

  @override
  bool checkParams() {
    return signature.isNotEmpty;
  }
}
