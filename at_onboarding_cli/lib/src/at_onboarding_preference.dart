import 'dart:core';

import 'package:at_client/at_client.dart';

class AtOnboardingPreference extends AtClientPreference {
  //specify path of .atKeysFile containing encryption keys
  String? atKeysFilePath;
  //specify path of qr code containing cram secret
  String? qrCodePath;
}
