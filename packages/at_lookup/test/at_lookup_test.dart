import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/outbound_message_listener.dart';
import 'package:at_utils/at_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'connection_management_test.dart';

class MockOutboundConnectionImpl extends Mock
    implements OutboundConnectionImpl {}

class MockSecondaryAddressFinder extends Mock
    implements SecondaryAddressFinder {}

class MockOutboundMessageListener extends Mock
    implements OutboundMessageListener {}

late int mockSocketNumber;

class MockSecureSocket extends Mock implements SecureSocket {
  bool destroyed = false;
  int mockNumber = mockSocketNumber++;
}

class MockSecureSocketFactory extends Mock
    implements AtLookupSecureSocketFactory {}

class MockSecureSocketListenerFactory extends Mock
    implements AtLookupSecureSocketListenerFactory {}

class MockOutboundConnectionFactory extends Mock
    implements AtLookupOutboundConnectionFactory {}

class MockAtChops extends Mock implements AtChopsImpl {}

class FakeAtSigningInput extends Fake implements AtSigningInput {}

SecureSocket createMockSecureSocket() {
  SecureSocket mss = MockSecureSocket();
  when(() => mss.destroy()).thenAnswer((invocation) {
    (mss as MockSecureSocket).destroyed = true;
  });
  when(() => mss.setOption(SocketOption.tcpNoDelay, true)).thenReturn(true);
  when(() => mss.remoteAddress).thenReturn(InternetAddress('127.0.0.1'));
  when(() => mss.remotePort).thenReturn(12345);
  when(() => mss.listen(any(),
      onError: any(named: "onError"),
      onDone: any(named: "onDone"))).thenReturn(MockStreamSubscription());
  return mss;
}

void main() {
  AtSignLogger.root_level = 'finest';
  mockSocketNumber = 1;
  late OutboundConnection mockOutBoundConnection;
  late SecondaryAddressFinder mockSecondaryAddressFinder;
  late OutboundMessageListener mockOutboundListener;
  late AtLookupSecureSocketFactory mockSocketFactory;
  late AtLookupSecureSocketListenerFactory mockSecureSocketListenerFactory;
  late AtLookupOutboundConnectionFactory mockOutboundConnectionFactory;

  late AtChops mockAtChops;
  late SecureSocket mockSecureSocket;

  setUp(() {
    mockOutBoundConnection = MockOutboundConnectionImpl();
    mockSecondaryAddressFinder = MockSecondaryAddressFinder();
    mockOutboundListener = MockOutboundMessageListener();
    mockSocketFactory = MockSecureSocketFactory();
    mockSecureSocketListenerFactory = MockSecureSocketListenerFactory();
    mockOutboundConnectionFactory = MockOutboundConnectionFactory();
    mockAtChops = MockAtChops();
    registerFallbackValue(SecureSocketConfig());
    mockSecureSocket = createMockSecureSocket();

    when(() => mockSecondaryAddressFinder.findSecondary('@alice'))
        .thenAnswer((_) async {
      return SecondaryAddress('127.0.0.1', 12345);
    });
    when(() => mockSocketFactory.createSocket('127.0.0.1', '12345', any()))
        .thenAnswer((invocation) {
      print('Mock SecureSocketFactory returning mock socket');
      return Future<SecureSocket>.value(mockSecureSocket);
    });
    when(() => mockOutboundConnectionFactory
        .createOutboundConnection(mockSecureSocket)).thenAnswer((invocation) {
      print('Creating mock outbound connection');
      return mockOutBoundConnection;
    });
    when(() => mockSecureSocketListenerFactory
        .createListener(mockOutBoundConnection)).thenAnswer((invocation) {
      print('creating mock outbound listener');
      return mockOutboundListener;
    });
    when(() => mockOutBoundConnection.write('from:@alice\n'))
        .thenAnswer((invocation) {
      mockSecureSocket.write('from:@alice\n');
      return Future.value();
    });
  });

  group('A group of tests to verify atlookup pkam authentication', () {
    test('Cram auth- auth success', () async {
      final secret =
          'b26455a907582760ebf35bc4847de549bc41c24b25c8b1c58d5964f7b4f8a43bc55b0e9a601c9a9657d9a8b8bbc32f88b4e38ffaca03c8710ebae1b14ca9f364';
      final digest =
          '0089cba2979e736652a6d2e7db7223c726bdf26191f6251640dc1c7576ed105f3818f7f071b65b73e070e0eb18ce9cdc212253c412635ceceb4cf24a00560039';
      when(() => mockOutboundListener.read(
              transientWaitTimeMillis: 4000, maxWaitMilliSeconds: 10000))
          .thenAnswer((_) => Future.value('data:success'));
      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);
      when(() => mockOutBoundConnection.write('from:@alice\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write('from:@alice\n');
        return Future.value();
      });
      when(() => mockOutBoundConnection.write('cram:$digest\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write('cram:$digest\n');
        return Future.value();
      });
      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      var result = await atLookup.authenticate_cram(secret);
      expect(result, true);
    });

    test('pkam auth without enrollmentId - auth success', () async {
      final pkamSignature =
          'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';

      AtSigningResult mockSigningResult = AtSigningResult()
        ..result = 'mock_signing_result';
      registerFallbackValue(FakeAtSigningInput());
      when(() => mockAtChops.sign(any())).thenAnswer((_) => mockSigningResult);

      when(() => mockAtChops.sign(any()))
          .thenReturn(AtSigningResult()..result = pkamSignature);
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value('data:success'));

      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);

      when(() => mockOutBoundConnection.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write(
            'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
        return Future.value();
      });

      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      var result = await atLookup.pkamAuthenticate();
      expect(result, true);
    });

    test('pkam auth without enrollmentId - auth failed', () async {
      final pkamSignature =
          'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';

      AtSigningResult mockSigningResult = AtSigningResult()
        ..result = 'mock_signing_result';
      registerFallbackValue(FakeAtSigningInput());
      when(() => mockAtChops.sign(any())).thenAnswer((_) => mockSigningResult);

      when(() => mockAtChops.sign(any()))
          .thenReturn(AtSigningResult()..result = pkamSignature);
      when(() => mockOutboundListener.read()).thenAnswer((_) =>
          Future.value('error:AT0401-Exception: pkam authentication failed'));

      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);

      when(() => mockOutBoundConnection.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write(
            'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
        return Future.value();
      });

      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      expect(() async => await atLookup.pkamAuthenticate(),
          throwsA(predicate((e) => e is UnAuthenticatedException)));
    });

    test('pkam auth with enrollmentId - auth success', () async {
      final pkamSignature =
          'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';
      final enrollmentIdFromServer = '5a21feb4-dc04-4603-829c-15f523789170';
      AtSigningResult mockSigningResult = AtSigningResult()
        ..result = 'mock_signing_result';
      registerFallbackValue(FakeAtSigningInput());
      when(() => mockAtChops.sign(any())).thenAnswer((_) => mockSigningResult);

      when(() => mockAtChops.sign(any()))
          .thenReturn(AtSigningResult()..result = pkamSignature);
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value('data:success'));

      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);

      when(() => mockOutBoundConnection.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write(
            'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
        return Future.value();
      });

      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      var result =
          await atLookup.pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
      expect(result, true);
    });

    test('pkam auth with enrollmentId - auth failed', () async {
      final pkamSignature =
          'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';
      final enrollmentIdFromServer = '5a21feb4-dc04-4603-829c-15f523789170';
      AtSigningResult mockSigningResult = AtSigningResult()
        ..result = 'mock_signing_result';
      registerFallbackValue(FakeAtSigningInput());
      when(() => mockAtChops.sign(any())).thenAnswer((_) => mockSigningResult);

      when(() => mockAtChops.sign(any()))
          .thenReturn(AtSigningResult()..result = pkamSignature);
      when(() => mockOutboundListener.read()).thenAnswer((_) =>
          Future.value('error:AT0401-Exception: pkam authentication failed'));

      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);

      when(() => mockOutBoundConnection.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write(
            'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
        return Future.value();
      });

      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      expect(
          () async => await atLookup.pkamAuthenticate(
              enrollmentId: enrollmentIdFromServer),
          throwsA(predicate((e) =>
              e is UnAuthenticatedException && e.message.contains('AT0401'))));
    });
  });
  group('A group of tests to verify executeCommand method', () {
    test('executeCommand - from verb - auth false', () async {
      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      final fromResponse =
          'data:_03fe0ff2-ac50-4c80-8f43-88480beba888@alice:c3d345fc-5691-4f90-bc34-17cba31f060f';
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value(fromResponse));
      var result = await atLookup.executeCommand('from:@alice\n');
      expect(result, fromResponse);
    });
    test('executeCommand -llookup verb - auth true - auth key not set',
        () async {
      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      final fromResponse = 'data:1234';
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value(fromResponse));
      expect(
          () async => await atLookup.executeCommand('llookup:phone@alice\n',
              auth: true),
          throwsA(predicate((e) => e is UnAuthenticatedException)));
    });

    test('executeCommand -update verb - auth true - auth key not set',
        () async {
      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      final fromResponse = 'data:1234';
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value(fromResponse));
      expect(
          () async => await atLookup
              .executeCommand('update:public:phone@alice 12344\n', auth: true),
          throwsA(predicate((e) => e is UnAuthenticatedException)));
    });

    test('executeCommand -delete verb - auth true - auth key not set',
        () async {
      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      final fromResponse = 'data:1234';
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value(fromResponse));
      expect(
          () async => await atLookup
              .executeCommand('delete:public:phone@alice\n', auth: true),
          throwsA(predicate((e) => e is UnAuthenticatedException)));
    });

    test('executeCommand -llookup verb - auth true - at_chops set', () async {
      final pkamSignature =
          'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';
      final enrollmentIdFromServer = '5a21feb4-dc04-4603-829c-15f523789170';
      AtSigningResult mockSigningResult = AtSigningResult()
        ..result = 'mock_signing_result';
      registerFallbackValue(FakeAtSigningInput());
      when(() => mockAtChops.sign(any())).thenAnswer((_) => mockSigningResult);

      when(() => mockAtChops.sign(any()))
          .thenReturn(AtSigningResult()..result = pkamSignature);
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value('data:success'));

      when(() => mockOutBoundConnection.getMetaData())
          .thenReturn(OutboundConnectionMetadata()..isAuthenticated = false);
      when(() => mockOutBoundConnection.isInValid()).thenReturn(false);

      when(() => mockOutBoundConnection.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
          .thenAnswer((invocation) {
        mockSecureSocket.write(
            'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
        return Future.value();
      });

      final atLookup = AtLookupImpl('@alice', '127.0.0.1', 64,
          secondaryAddressFinder: mockSecondaryAddressFinder,
          secureSocketFactory: mockSocketFactory,
          socketListenerFactory: mockSecureSocketListenerFactory,
          outboundConnectionFactory: mockOutboundConnectionFactory);
      atLookup.atChops = mockAtChops;
      var result =
          await atLookup.pkamAuthenticate(enrollmentId: enrollmentIdFromServer);
      expect(result, true);
      final llookupCommand = 'llookup:phone@alice\n';
      final llookupResponse = 'data:1234';
      when(() => mockOutBoundConnection.write(llookupCommand))
          .thenAnswer((invocation) {
        mockSecureSocket.write(llookupCommand);
        return Future.value();
      });
      when(() => mockOutboundListener.read())
          .thenAnswer((_) => Future.value(llookupResponse));
      var executeCommandresult =
          await atLookup.executeCommand(llookupCommand, auth: true);
      expect(executeCommandresult, llookupResponse);
    });
  });
}
