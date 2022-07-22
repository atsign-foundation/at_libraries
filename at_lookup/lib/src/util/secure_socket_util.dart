import 'dart:io';
import 'package:at_commons/at_commons.dart';

class SecureSocketUtil {
  ///method that creates and returns a [SecureSocket]. If [decryptPackets] is set to true,the TLS keys are logged into a file.
  static Future<SecureSocket> createSecureSocket(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    if (!secureSocketConfig.decryptPackets) {
      return await SecureSocket.connect(host, int.parse(port));
    } else {
      SecurityContext securityContext = SecurityContext();
      try {
        File keysFile = File(secureSocketConfig.tlsKeysSavePath!);
        if (secureSocketConfig.pathToCerts != null) {
          securityContext
              .setTrustedCertificates(secureSocketConfig.pathToCerts!);
        } else {
          throw AtException(
              'decryptPackets set to true but path to trusted certificated not provided');
        }
        return await SecureSocket.connect(host, int.parse(port),
            context: securityContext,
            keyLog: (line) =>
                keysFile.writeAsStringSync(line, mode: FileMode.append));
      } catch (e) {
        throw AtException(e.toString());
      }
    }
  }
}
