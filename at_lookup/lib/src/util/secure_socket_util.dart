import 'dart:io';
class SecureSocketUtil{
  ///method that creates and returns a [SecureSocket]. If [decryptPackets] is set to true,the TLS keys are logged into a file.
  static Future<SecureSocket> createSecureContext(host, port, {decryptPackets = false}){
    if (decryptPackets){
      SecurityContext securityContext = SecurityContext();
      File keysFile = File('tls_keys_file');
      //securityContext.setTrustedCertificates();
      return SecureSocket.connect(host, int.parse(port), context: securityContext, keyLog: (line) => keysFile.writeAsStringSync(line, mode: FileMode.append));
    }
    else{
      return SecureSocket.connect(host, int.parse(port));
    }
  }
}