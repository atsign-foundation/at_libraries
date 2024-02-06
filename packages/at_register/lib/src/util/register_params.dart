import 'package:at_commons/at_commons.dart';

class RegisterParams {
  String? atsign;
  String? email;
  String? oldEmail;
  bool confirmation = true;
  String? otp;
  String? cram;


  /// Populates the current instance of [RegisterParams] using the fields from the json
  ///
  /// Usage:
  ///
  /// ```RegisterParams params = RegisterParams();```
  ///
  /// ```params.addFromJson(json);```
  addFromJson(Map<dynamic, dynamic> json) {
    if (json.containsKey('atsign')) {
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
    if (json.containsKey('cramkey')) {
      cram = json['cramkey'];
    }
  }

  @override
  String toString() {
    return 'atsign: $atsign | email: $email | otp: ${otp.isNullOrEmpty ? 'null' : '****'} | oldEmail: $oldEmail | confirmation: $confirmation';
  }
}
