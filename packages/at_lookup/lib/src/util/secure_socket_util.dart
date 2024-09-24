import 'dart:io';
import 'package:at_commons/at_commons.dart';

class SecureSocketUtil {
  /// Method that creates and returns either a [SecureSocket] or a [WebSocket].
  /// If [decryptPackets] is set to true, the TLS keys are logged into a file.
  static Future<dynamic> createSecureSocket(
      String host, String port, SecureSocketConfig secureSocketConfig,
      {bool isWebSocket = false}) async {
    if (isWebSocket) {
      return createSecureWebSocket(host, port, secureSocketConfig);
    } else {
      return _createSecureSocket(host, port, secureSocketConfig);
    }
  }

  /// Creates a secure WebSocket connection.
  static Future<WebSocket> createSecureWebSocket(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    try {
      final uri = Uri.parse('wss://$host:$port');
      WebSocket webSocket = await WebSocket.connect(uri.toString());
      return webSocket;
    } catch (e) {
      throw AtException('Error creating WebSocket connection: ${e.toString()}');
    }
  }

  /// Creates a secure socket connection (SecureSocket).
  static Future<SecureSocket> _createSecureSocket(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    SecureSocket? secureSocket;
    if (!secureSocketConfig.decryptPackets) {
      secureSocket = await SecureSocket.connect(host, int.parse(port));
      secureSocket.setOption(SocketOption.tcpNoDelay, true);
      return secureSocket;
    } else {
      SecurityContext securityContext = SecurityContext();
      try {
        File keysFile = File(secureSocketConfig.tlsKeysSavePath!);
        if (secureSocketConfig.pathToCerts != null &&
            await File(secureSocketConfig.pathToCerts!).exists()) {
          securityContext
              .setTrustedCertificates(secureSocketConfig.pathToCerts!);
        } else {
          throw AtException(
              'decryptPackets set to true but path to trusted certificates not provided');
        }
        secureSocket = await SecureSocket.connect(host, int.parse(port),
            context: securityContext,
            keyLog: (line) =>
                keysFile.writeAsStringSync(line, mode: FileMode.append));
        secureSocket.setOption(SocketOption.tcpNoDelay, true);
        return secureSocket;
      } catch (e) {
        throw AtException(
            'Error creating SecureSocket connection: ${e.toString()}');
      }
    }
  }
}
