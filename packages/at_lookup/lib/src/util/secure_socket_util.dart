import 'dart:io';
import 'package:at_commons/at_commons.dart';

class SecureSocketUtil {
  ///method that creates and returns a [SecureSocket]. If [decryptPackets] is set to true,the TLS keys are logged into a file.
  static Future<SecureSocket> createSecureSocket(
      String host, String port, SecureSocketConfig secureSocketConfig, {Duration? socketConnectTimeout}) async {
    SecureSocket? _secureSocket;
    try {
      if (!secureSocketConfig.decryptPackets) {
        _secureSocket = await SecureSocket.connect(host, int.parse(port), timeout: socketConnectTimeout);
        _secureSocket.setOption(SocketOption.tcpNoDelay, true);
        return _secureSocket;
      } else {
        SecurityContext securityContext = SecurityContext();
        File keysFile = File(secureSocketConfig.tlsKeysSavePath!);
        if (secureSocketConfig.pathToCerts != null && await File(secureSocketConfig.pathToCerts!).exists()) {
          securityContext.setTrustedCertificates(secureSocketConfig.pathToCerts!);
        } else {
          throw AtException('decryptPackets set to true but path to trusted certificated not provided');
        }
        _secureSocket = await SecureSocket.connect(host, int.parse(port),
            context: securityContext, keyLog: (line) => keysFile.writeAsStringSync(line, mode: FileMode.append),
            timeout: socketConnectTimeout);
        _secureSocket.setOption(SocketOption.tcpNoDelay, true);
        return _secureSocket;
      }
    } catch (e) {
      throw AtException(e.toString());
    }
  }
}
