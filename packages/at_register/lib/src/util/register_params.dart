import 'package:at_commons/at_commons.dart';
import 'package:at_register/at_register.dart';

class RegisterParams {
  String? atsign;
  String? email;
  String? oldEmail;
  bool confirmation = true;
  String? otp;
  String? cram;
  List<String>? fetchedAtsignsList;


  /// Populates the current instance of [RegisterParams] using the fields from the json
  ///
  /// Usage:
  ///
  /// ```RegisterParams params = RegisterParams();```
  ///
  /// ```params.addFromJson(json);```
  addFromJson(Map<dynamic, dynamic> json) {
    if (json.containsKey('atsign') && json['atsign'].runtimeType == String) {
      atsign = json['atsign'];
    }
    if (json.containsKey('otp')) {
      otp = json['otp'];
    }
    if (json.containsKey('email')) {
      email = json['email'];
    }
    if (json.containsKey('oldEmail')) {
      oldEmail = json['oldEmail'];
    }
    if (json.containsKey(RegistrarConstants.cramKey)) {
      cram = json['cramkey'];
    }
  }

  @override
  String toString() {
    return 'atsign: $atsign | email: $email | otp: ${otp.isNullOrEmpty ? 'null' : '****'} | oldEmail: $oldEmail | confirmation: $confirmation';
  }
}
