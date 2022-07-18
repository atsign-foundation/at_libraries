import 'dart:io';
import 'package:at_commons/at_commons.dart';

class SecureSocketUtil {
  static late bool decryptPackets;

  ///method that creates and returns a [SecureSocket]. If [decryptPackets] is set to true,the TLS keys are logged into a file.
  static Future<SecureSocket> createSecureSocket(
      String host,
      String port,
      bool? decryptPackets,
      String? pathToCerts,
      String? tlsKeysSavePath) async {
    SecureSocketUtil.decryptPackets = decryptPackets ?? false;
    if (SecureSocketUtil.decryptPackets) {
      SecurityContext securityContext = SecurityContext();
      try {
        File keysFile = File(tlsKeysSavePath!);
        securityContext.setTrustedCertificates(pathToCerts!);
        return await SecureSocket.connect(host, int.parse(port),
            context: securityContext,
            keyLog: (line) =>
                keysFile.writeAsStringSync(line, mode: FileMode.append));
      } catch (e) {
        throw AtException(e.toString());
      }
    } else {
      return await SecureSocket.connect(host, int.parse(port));
    }
  }
}
