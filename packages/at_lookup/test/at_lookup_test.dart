import 'dart:async';
import 'dart:io';

import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/at_message_listener.dart';
import 'package:at_utils/at_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'at_lookup_test_utils.dart';

class FakeAtSigningInput extends Fake implements AtSigningInput {}

void main() {
  AtSignLogger.root_level = 'finest';
  late AtConnection mockAtConnection;

  late SecondaryAddressFinder mockSecondaryAddressFinder;
  late AtMessageListener mockAtMessageListener;
  late AtLookupConnectionFactory mockAtConnectionFactory;

  late AtChops mockAtChops;
  late SecureSocket mockSecureSocket;
  late WebSocket mockWebSocket;

  String atServerHost = '127.0.0.1';
  int atServerPort = 12345;

  group('A group of secure socket tests', () {
    setUp(() {
      mockAtConnection = MockAtSocketConnection();
      mockSecondaryAddressFinder = MockSecondaryAddressFinder();
      mockAtMessageListener = MockAtMessageListener();
      mockAtConnectionFactory = MockAtLookupConnectionFactory();
      mockAtChops = MockAtChops();

      registerFallbackValue(SecureSocketConfig());
      mockSecureSocket = createMockAtServerSocket(atServerHost, atServerPort);

      when(() => mockSecondaryAddressFinder.findSecondary('@alice'))
          .thenAnswer((_) async {
        return SecondaryAddress(atServerHost, atServerPort);
      });

      when(() => mockAtConnectionFactory.createUnderlying(
          atServerHost, '12345', any())).thenAnswer((_) {
        return Future<SecureSocket>.value(mockSecureSocket);
      });

      when(() => mockAtConnectionFactory.createConnection(mockSecureSocket))
          .thenAnswer((_) => mockAtConnection);

      when(() => mockAtConnection.write(any()))
          .thenAnswer((_) => Future.value());

      when(() => mockAtConnectionFactory.createListener(mockAtConnection))
          .thenAnswer((_) => mockAtMessageListener);
    });

    group('A group of tests to verify atlookup pkam authentication', () {
      test('pkam auth without enrollmentId - auth success', () async {
        final pkamSignature =
            'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';

        AtSigningResult mockSigningResult = AtSigningResult()
          ..result = 'mock_signing_result';
        registerFallbackValue(FakeAtSigningInput());
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value('data:success'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockSecureSocket.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        // Override atConnectionFactory with mock in AtLookupImpl
        atLookup.atConnectionFactory = mockAtConnectionFactory;
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
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read()).thenAnswer((_) =>
            Future.value('error:AT0401-Exception: pkam authentication failed'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockSecureSocket.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        // Override atConnectionFactory with mock in AtLookupImpl
        atLookup.atConnectionFactory = mockAtConnectionFactory;
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
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value('data:success'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockSecureSocket.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        var result = await atLookup.pkamAuthenticate(
            enrollmentId: enrollmentIdFromServer);
        expect(result, true);
      });

      test('pkam auth with enrollmentId - auth failed', () async {
        final pkamSignature =
            'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';
        final enrollmentIdFromServer = '5a21feb4-dc04-4603-829c-15f523789170';
        AtSigningResult mockSigningResult = AtSigningResult()
          ..result = 'mock_signing_result';
        registerFallbackValue(FakeAtSigningInput());
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read()).thenAnswer((_) =>
            Future.value('error:AT0401-Exception: pkam authentication failed'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);
        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockSecureSocket.write(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        expect(
            () async => await atLookup.pkamAuthenticate(
                enrollmentId: enrollmentIdFromServer),
            throwsA(predicate((e) =>
                e is UnAuthenticatedException &&
                e.message.contains('AT0401'))));
      });
    });

    group('A group of tests to verify executeCommand method', () {
      test('executeCommand - from verb - auth false', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        final fromResponse =
            'data:_03fe0ff2-ac50-4c80-8f43-88480beba888@alice:c3d345fc-5691-4f90-bc34-17cba31f060f';
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(fromResponse));
        var result = await atLookup.executeCommand('from:@alice\n');
        expect(result, fromResponse);
      }, timeout: Timeout(Duration(minutes: 5)));

      test('executeCommand -llookup verb - auth true - auth key not set',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        final fromResponse = 'data:1234';
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(fromResponse));
        expect(
            () async => await atLookup.executeCommand('llookup:phone@alice\n',
                auth: true),
            throwsA(predicate((e) => e is UnAuthenticatedException)));
      });

      test('executeCommand -llookup verb - auth true - at_chops set', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        final llookupCommand = 'llookup:phone@alice\n';
        final llookupResponse = 'data:1234';
        when(() => mockAtConnection.write(llookupCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(llookupCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(llookupResponse));
        var result = await atLookup.executeCommand(llookupCommand);
        expect(result, llookupResponse);
      });

      test('executeCommand - test non json error handling', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        final llookupCommand = 'llookup:phone@alice\n';
        final llookupResponse = 'error:AT0015-Exception: fubar';
        when(() => mockAtConnection.write(llookupCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(llookupCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(llookupResponse));
        await expectLater(
            atLookup.executeCommand(llookupCommand),
            throwsA(predicate((e) =>
                e is AtLookUpException &&
                e.errorMessage == 'Exception: fubar')));
      });

      test('executeCommand - test json error handling', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        final llookupCommand = 'llookup:phone@alice\n';
        final llookupResponse =
            'error:{"errorCode":"AT0015","errorDescription":"Exception: fubar"}';
        when(() => mockAtConnection.write(llookupCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(llookupCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(llookupResponse));
        await expectLater(
            atLookup.executeCommand(llookupCommand),
            throwsA(predicate((e) =>
                e is AtLookUpException &&
                e.errorMessage == 'Exception: fubar')));
      });
    });

    group('Validate executeVerb() behaviour', () {
      test('validate EnrollVerbHandler behaviour - request', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String appName = 'unit_test_1';
        String deviceName = 'test_device';
        String otp = 'ABCDEF';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.request
          ..appName = appName
          ..deviceName = deviceName
          ..otp = otp;
        String enrollCommand =
            'enroll:request:{"appName":"$appName","deviceName":"$deviceName","otp":"$otp"}\n';
        final enrollResponse =
            'data:{"enrollmentId":"1234567890","status":"pending"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = false;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        var result = await atLookup.executeVerb(enrollVerbBuilder);
        expect(result, enrollResponse);
      });

      test('validate behaviour with EnrollVerbHandler - approve', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atChops = mockAtChops;
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String appName = 'unit_test_2';
        String deviceName = 'test_device';
        String enrollmentId = '1357913579';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.approve
          ..enrollmentId = '1357913579'
          ..appName = appName
          ..deviceName = deviceName;
        String enrollCommand =
            'enroll:approve:{"enrollmentId":"$enrollmentId","appName":"$appName","deviceName":"$deviceName"}\n';
        final enrollResponse =
            'data:{"enrollmentId":"1357913579","status":"approved"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });

      test('validate behaviour with EnrollVerbHandler - revoke', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atChops = mockAtChops;
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String enrollmentId = '89213647826348';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.revoke
          ..enrollmentId = enrollmentId;
        String enrollCommand =
            'enroll:revoke:{"enrollmentId":"$enrollmentId"}\n';
        String enrollResponse =
            'data:{"enrollmentId":"$enrollmentId","status":"revoked"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });

      test('validate behaviour with EnrollVerbHandler - deny', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder);
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        String enrollmentId = '5754765754';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.deny
          ..enrollmentId = enrollmentId;
        String enrollCommand = 'enroll:deny:{"enrollmentId":"$enrollmentId"}\n';
        String enrollResponse =
            'data:{"enrollmentId":"$enrollmentId","status":"denied"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockSecureSocket.write(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });
    });
  });

  group('A group of web socket tests', () {
    setUp(() {
      mockAtConnection = MockAtSocketConnection();
      mockSecondaryAddressFinder = MockSecondaryAddressFinder();
      mockAtMessageListener = MockAtMessageListener();
      mockAtConnectionFactory = MockAtLookupConnectionFactory();
      mockAtChops = MockAtChops();
      registerFallbackValue(SecureSocketConfig());
      mockWebSocket = createMockWebSocket(atServerHost, atServerPort);

      when(() => mockSecondaryAddressFinder.findSecondary('@alice'))
          .thenAnswer((_) async {
        return SecondaryAddress(atServerHost, atServerPort);
      });

      when(() => mockAtConnectionFactory.createUnderlying(
          atServerHost, '12345', any())).thenAnswer((_) {
        return Future<WebSocket>.value(mockWebSocket);
      });

      when(() => mockAtConnectionFactory.createConnection(mockWebSocket))
          .thenAnswer((_) => mockAtConnection);

      when(() => mockAtConnection.write(any()))
          .thenAnswer((_) => Future.value());

      when(() => mockAtConnectionFactory.createListener(mockAtConnection))
          .thenAnswer((_) => mockAtMessageListener);
    });

    group('A group of tests to verify atlookup pkam authentication', () {
      test('pkam auth using websocket without enrollmentId - auth success',
          () async {
        final pkamSignature =
            'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';

        AtSigningResult mockSigningResult = AtSigningResult()
          ..result = 'mock_signing_result';
        registerFallbackValue(FakeAtSigningInput());
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value('data:success'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockWebSocket.add(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        // Override atConnectionFactory with mock in AtLookupImpl
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        var result = await atLookup.pkamAuthenticate();
        expect(result, true);
      }, timeout: Timeout(Duration(minutes: 2)));

      test('pkam auth using a websocket without enrollmentId - auth failed',
          () async {
        final pkamSignature =
            'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';

        AtSigningResult mockSigningResult = AtSigningResult()
          ..result = 'mock_signing_result';
        registerFallbackValue(FakeAtSigningInput());
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read()).thenAnswer((_) =>
            Future.value('error:AT0401-Exception: pkam authentication failed'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockWebSocket.add(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        // Override atConnectionFactory with mock in AtLookupImpl
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        expect(() async => await atLookup.pkamAuthenticate(),
            throwsA(predicate((e) => e is UnAuthenticatedException)));
      });

      test('pkam auth using a websocket with enrollmentId - auth success',
          () async {
        final pkamSignature =
            'MbNbIwCSxsHxm4CHyakSE2yLqjjtnmzpSLPcGG7h+4M/GQAiJkklQfd/x9z58CSJfuSW8baIms26SrnmuYePZURfp5oCqtwRpvt+l07Gnz8aYpXH0k5qBkSR34SBk4nb+hdAjsXXgfWWC56gROPMwpOEbuDS6esU7oku+a7Rdr10xrFlk1Tf2eRwPOMWyuKwOvLwSgyq/INAFRYav5RmLFiecQhPME6ssc1jW92wztylKBtuZT4rk8787b6Z9StxT4dPZzWjfV1+oYDLaqu2PcQS2ZthH+Wj8NgoogDxSP+R7BE1FOVJKnavpuQWeOqNWeUbKkSVP0B0DN6WopAdsg==';
        final enrollmentIdFromServer = '5a21feb4-dc04-4603-829c-15f523789170';
        AtSigningResult mockSigningResult = AtSigningResult()
          ..result = 'mock_signing_result';
        registerFallbackValue(FakeAtSigningInput());
        when(() => mockAtChops.sign(any()))
            .thenAnswer((_) => mockSigningResult);

        when(() => mockAtChops.sign(any()))
            .thenReturn(AtSigningResult()..result = pkamSignature);
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value('data:success'));

        when(() => mockAtConnection.metaData)
            .thenReturn(AtConnectionMetaData()..isAuthenticated = false);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        when(() => mockAtConnection.write(
                'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n'))
            .thenAnswer((invocation) {
          mockWebSocket.add(
              'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:enrollmentId:$enrollmentIdFromServer:$pkamSignature\n');
          return Future.value();
        });

        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        var result = await atLookup.pkamAuthenticate(
            enrollmentId: enrollmentIdFromServer);
        expect(result, true);
      });
    });

    group('A group of tests to verify executeCommand method', () {
      test('executeCommand  using websocket- from verb - auth false', () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        final fromResponse =
            'data:_03fe0ff2-ac50-4c80-8f43-88480beba888@alice:c3d345fc-5691-4f90-bc34-17cba31f060f';
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(fromResponse));
        var result = await atLookup.executeCommand('from:@alice\n');
        expect(result, fromResponse);
      }, timeout: Timeout(Duration(minutes: 5)));

      test(
          'executeCommand using websocket-llookup verb - auth true - auth key not set',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        final fromResponse = 'data:1234';
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(fromResponse));
        expect(
            () async => await atLookup.executeCommand('llookup:phone@alice\n',
                auth: true),
            throwsA(predicate((e) => e is UnAuthenticatedException)));
      });
    });

    group('Validate executeVerb() behaviour', () {
      test(
          'validate EnrollVerbHandler behaviour using a websocket connection- request',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String appName = 'unit_test_1';
        String deviceName = 'test_device';
        String otp = 'ABCDEF';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.request
          ..appName = appName
          ..deviceName = deviceName
          ..otp = otp;
        String enrollCommand =
            'enroll:request:{"appName":"$appName","deviceName":"$deviceName","otp":"$otp"}\n';
        final enrollResponse =
            'data:{"enrollmentId":"1234567890","status":"pending"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockWebSocket.add(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = false;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        var result = await atLookup.executeVerb(enrollVerbBuilder);
        expect(result, enrollResponse);
      });

      test(
          'validate behaviour with EnrollVerbHandler  using a websocket connection- approve',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atChops = mockAtChops;
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String appName = 'unit_test_2';
        String deviceName = 'test_device';
        String enrollmentId = '1357913579';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.approve
          ..enrollmentId = '1357913579'
          ..appName = appName
          ..deviceName = deviceName;
        String enrollCommand =
            'enroll:approve:{"enrollmentId":"$enrollmentId","appName":"$appName","deviceName":"$deviceName"}\n';
        final enrollResponse =
            'data:{"enrollmentId":"1357913579","status":"approved"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockWebSocket.add(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });

      test(
          'validate behaviour with EnrollVerbHandler using a websocket connection - revoke',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atChops = mockAtChops;
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        String enrollmentId = '89213647826348';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.revoke
          ..enrollmentId = enrollmentId;
        String enrollCommand =
            'enroll:revoke:{"enrollmentId":"$enrollmentId"}\n';
        String enrollResponse =
            'data:{"enrollmentId":"$enrollmentId","status":"revoked"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockWebSocket.add(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });

      test(
          'validate behaviour with EnrollVerbHandler using a websocket connection - deny',
          () async {
        final atLookup = AtLookupImpl('@alice', atServerHost, 64,
            secondaryAddressFinder: mockSecondaryAddressFinder,
            atConnectionFactory: AtLookupWebSocketFactory());
        atLookup.atConnectionFactory = mockAtConnectionFactory;
        atLookup.atChops = mockAtChops;
        String enrollmentId = '5754765754';

        EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
          ..operation = EnrollOperationEnum.deny
          ..enrollmentId = enrollmentId;
        String enrollCommand = 'enroll:deny:{"enrollmentId":"$enrollmentId"}\n';
        String enrollResponse =
            'data:{"enrollmentId":"$enrollmentId","status":"denied"}';

        when(() => mockAtConnection.write(enrollCommand))
            .thenAnswer((invocation) {
          mockWebSocket.add(enrollCommand);
          return Future.value();
        });
        when(() => mockAtMessageListener.read())
            .thenAnswer((_) => Future.value(enrollResponse));
        AtConnectionMetaData? atConnectionMetaData = AtConnectionMetaData()
          ..isAuthenticated = true;
        when(() => mockAtConnection.metaData).thenReturn(atConnectionMetaData);
        when(() => mockAtConnection.isInValid()).thenReturn(false);

        expect(await atLookup.executeVerb(enrollVerbBuilder), enrollResponse);
      });
    });
  });
}
