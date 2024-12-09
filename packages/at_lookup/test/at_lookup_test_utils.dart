import 'dart:async';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_message_listener.dart';
import 'package:at_lookup/src/connection/at_socket_connection.dart';
import 'package:mocktail/mocktail.dart';

int mockSocketNumber = 1;

class MockSecondaryAddressFinder extends Mock
    implements SecondaryAddressFinder {}

class MockSecondaryUrlFinder extends Mock implements SecondaryUrlFinder {}

class MockAtLookupConnectionFactory extends Mock
    implements AtConnectionFactory {}

class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}

class MockSecureSocket extends Mock implements SecureSocket {
  bool destroyed = false;
  int mockNumber = mockSocketNumber++;
}

class MockWebSocket extends Mock implements WebSocket {
  bool destroyed = false;
  int mockNumber = mockSocketNumber++;
}

class MockAtMessageListener extends Mock implements AtMessageListener {}

class MockAtChops extends Mock implements AtChopsImpl {}

class MockAtSocketConnection extends Mock implements AtSocketConnection {}

SecureSocket createMockAtServerSocket(String address, int port) {
  SecureSocket mss = MockSecureSocket();
  when(() => mss.destroy()).thenAnswer((invocation) {
    (mss as MockSecureSocket).destroyed = true;
  });
  when(() => mss.setOption(SocketOption.tcpNoDelay, true)).thenReturn(true);
  when(() => mss.remoteAddress).thenReturn(InternetAddress('127.0.0.66'));
  when(() => mss.remotePort).thenReturn(port);
  when(() => mss.listen(any(),
      onError: any(named: "onError"),
      onDone: any(named: "onDone"))).thenReturn(MockStreamSubscription());
  return mss;
}

WebSocket createMockWebSocket(String address, int port) {
  var mockWebSocket = MockWebSocket();
  when(() => mockWebSocket.close(any(), any())).thenAnswer((_) async {
    (mockWebSocket).destroyed = true;
  });
  when(() => mockWebSocket.add(any())).thenReturn(null);
  when(() => mockWebSocket.listen(any(),
          onError: any(named: "onError"),
          onDone: any(named: "onDone"),
          cancelOnError: any(named: "cancelOnError")))
      .thenReturn(MockStreamSubscription());
  return mockWebSocket;
}
