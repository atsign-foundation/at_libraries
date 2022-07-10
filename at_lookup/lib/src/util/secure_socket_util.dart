import 'dart:io';

class SecureSocketUtil {

  ///method that creates and returns a [SecureSocket]. If [decryptPackets] is set to true,the TLS keys are logged into a file.
  static Future<SecureSocket> createSecureContext(String host, String port, bool decryptPackets, String? pathToCerts, String? tlsKeysSavePath) async {
    if (decryptPackets) {
      SecurityContext securityContext = SecurityContext();
      File keysFile = File(tlsKeysSavePath!);
      securityContext.setTrustedCertificates(pathToCerts!);
      return await SecureSocket.connect(host, int.parse(port),
          context: securityContext,
          keyLog: (line) =>
              keysFile.writeAsStringSync(line, mode: FileMode.append));
    } else {
      return await SecureSocket.connect(host, int.parse(port));
    }
  }
}
