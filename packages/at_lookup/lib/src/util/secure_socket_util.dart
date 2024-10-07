import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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


static Future<WebSocket> createSecureWebSocket(
      String host, String port, SecureSocketConfig secureSocketConfig) async {
    try {
      SecureSocket socket = await SecureSocket.connect(
        host,
        int.parse(port),
        supportedProtocols: ['http/1.1'], // Request 'http/1.1' during ALPN
      );

      if (socket.selectedProtocol != 'http/1.1') {
        throw AtException('Failed to negotiate http/1.1 via ALPN');
      }

      String webSocketKey =
          base64.encode(List<int>.generate(16, (_) => Random().nextInt(256)));
      socket.write('GET /ws HTTP/1.1\r\n');
      socket.write('Host: $host:$port\r\n');
      socket.write('Connection: Upgrade\r\n');
      socket.write('Upgrade: websocket\r\n');
      socket.write('Sec-WebSocket-Version: 13\r\n');
      socket.write('Sec-WebSocket-Key: $webSocketKey\r\n');
      socket.write('\r\n');

      WebSocket webSocket = WebSocket.fromUpgradedSocket(
        socket,
        serverSide: false,
      );

      print('WebSocket connection established');
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
