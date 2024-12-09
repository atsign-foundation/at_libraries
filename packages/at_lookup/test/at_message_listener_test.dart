import 'dart:async';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/at_message_listener.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'at_lookup_test_utils.dart';

void main() {
  AtConnection mockAtConnection = MockAtSocketConnection();

  group('A group of tests to verify buffer of AtMessageListener', () {
    AtMessageListener atMessageListener = AtMessageListener(mockAtConnection);
    test('A test to validate complete data comes in single packet', () async {
      atMessageListener.messageHandler('data:phone@alice\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:phone@alice');
    });

    test(
        'A test to validate complete data comes in packet and prompt in different packet',
        () async {
      atMessageListener.messageHandler('data:@bob:phone@alice\n'.codeUnits);
      atMessageListener.messageHandler('@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:@bob:phone@alice');
    });

    test('A test to validate data two complete data comes in single packets',
        () async {
      atMessageListener
          .messageHandler('data:@bob:phone@alice\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:@bob:phone@alice');
      atMessageListener
          .messageHandler('data:public:phone@alice\n@alice@'.codeUnits);
      response = await atMessageListener.read();
      expect(response, 'data:public:phone@alice');
    });

    test('A test to validate data two complete data comes in multiple packets',
        () async {
      atMessageListener
          .messageHandler('data:public:phone@alice\n@ali'.codeUnits);
      atMessageListener.messageHandler('ce@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:public:phone@alice');
      atMessageListener.messageHandler(
          'data:@bob:location@alice,@bob:phone@alice\n@alice@'.codeUnits);
      response = await atMessageListener.read();
      expect(response, 'data:@bob:location@alice,@bob:phone@alice');
    });

    test('A test to validate single data comes two packets', () async {
      atMessageListener.messageHandler('data:public:phone@'.codeUnits);
      atMessageListener.messageHandler('alice\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:public:phone@alice');
    });

    test('A test to validate data contains @', () async {
      atMessageListener
          .messageHandler('data:phone@alice_12345675\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:phone@alice_12345675');
    });

    test(
        'A test to validate data contains @ and partial prompt of previous data',
        () async {
      // partial response of previous data.
      atMessageListener.messageHandler('data:hello\n@'.codeUnits);
      atMessageListener.messageHandler('alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:hello');
      atMessageListener
          .messageHandler('data:phone@alice_12345675\n@alice@'.codeUnits);
      response = await atMessageListener.read();
      expect(response, 'data:phone@alice_12345675');
    });

    test('A test to validate data contains new line character', () async {
      atMessageListener.messageHandler(
          'data:value_contains_\nin_the_value\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:value_contains_\nin_the_value');
    });

    test('A test to validate data contains new line character and @', () async {
      atMessageListener.messageHandler(
          'data:the_key_is\n@bob:phone@alice\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:the_key_is\n@bob:phone@alice');
    });
  });

  group('A group of test to verify response from unauthorized connection', () {
    AtMessageListener atMessageListener = AtMessageListener(mockAtConnection);
    test('A test to validate response from unauthorized connection', () async {
      atMessageListener.messageHandler('data:hello\n@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:hello');
    });

    test('A test to validate multiple response from unauthorized connection',
        () async {
      atMessageListener.messageHandler('data:hello\n@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:hello');
      atMessageListener.messageHandler('data:hi\n@'.codeUnits);
      response = await atMessageListener.read();
      expect(response, 'data:hi');
    });

    test(
        'A test to validate response from unauthorized connection in multiple packets',
        () async {
      atMessageListener.messageHandler('data:public:location@alice,'.codeUnits);
      atMessageListener.messageHandler('public:phone@alice\n@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'data:public:location@alice,public:phone@alice');
      atMessageListener.messageHandler('data:hi\n@'.codeUnits);
      response = await atMessageListener.read();
      expect(response, 'data:hi');
    });
  });

  group('A group of test to validate buffer over flow scenarios', () {
    test('A test to verify buffer over flow exception', () {
      AtMessageListener atMessageListener =
          AtMessageListener(mockAtConnection, bufferCapacity: 10);
      expect(
          () => atMessageListener
              .messageHandler('data:dummy_data_to_exceed_limit'.codeUnits),
          throwsA(predicate((dynamic e) =>
              e is BufferOverFlowException &&
              e.message ==
                  'data length exceeded the buffer limit. Data length : 31 and Buffer capacity 10')));
    });

    test('A test to verify buffer over flow with multiple data packets', () {
      AtMessageListener atMessageListener =
          AtMessageListener(mockAtConnection, bufferCapacity: 20);
      atMessageListener.messageHandler('data:dummy_data'.codeUnits);
      expect(
          () => atMessageListener
              .messageHandler('to_exceed_limit\n@alice@'.codeUnits),
          throwsA(predicate((dynamic e) =>
              e is BufferOverFlowException &&
              e.message ==
                  'data length exceeded the buffer limit. Data length : 38 and Buffer capacity 20')));
    });
  });

  group('A group of tests to verify error: and stream responses from server',
      () {
    AtMessageListener atMessageListener = AtMessageListener(mockAtConnection);
    test('A test to validate complete error comes in single packet', () async {
      atMessageListener.messageHandler(
          'error:AT0012: Invalid value found\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'error:AT0012: Invalid value found');
    });

    test('A test to validate complete error comes in single packet', () async {
      atMessageListener
          .messageHandler('stream:@bob:phone@alice\n@alice@'.codeUnits);
      var response = await atMessageListener.read();
      expect(response, 'stream:@bob:phone@alice');
    });
  });

  group('A group of tests to verify AtTimeOutException', () {
    AtMessageListener atMessageListener = AtMessageListener(mockAtConnection);
    setUp(() {
      when(() => mockAtConnection.isInValid()).thenAnswer((_) => false);
      when(() => mockAtConnection.close())
          .thenAnswer((Invocation invocation) async {});
    });
    test(
        'A test to verify when no data is received from server within transientWaitTimeMillis',
        () async {
      expect(
          () async => await atMessageListener.read(transientWaitTimeMillis: 50),
          throwsA(predicate((dynamic e) =>
              e is AtTimeoutException &&
              e.message
                  .startsWith('Waited for 50 millis. No response after'))));
    });
    test(
        'A test to verify no response from server- wait time greater than maxWaitMillis',
        () async {
      expect(
          () async =>
              // we want to trigger the maxWaitMilliSeconds exception, so setting transient to a higher value
              await atMessageListener.read(
                  transientWaitTimeMillis: 100, maxWaitMilliSeconds: 50),
          throwsA(predicate((dynamic e) =>
              e is AtTimeoutException &&
              e.message.startsWith(
                  'Full response not received after 50 millis from remote secondary'))));
    });
    test(
        'A test to verify partial response - wait time greater than transientWaitTimeMillis',
        () async {
      atMessageListener.messageHandler('data:public:phone@'.codeUnits);
      atMessageListener.messageHandler('12'.codeUnits);
      expect(
          () async => await atMessageListener.read(transientWaitTimeMillis: 50),
          throwsA(predicate((dynamic e) =>
              e is AtTimeoutException &&
              e.message
                  .startsWith('Waited for 50 millis. No response after'))));
    });
    test(
        'A test to verify partial response - wait time greater than maxWaitMillis',
        () async {
      atMessageListener.messageHandler('data:public:phone@'.codeUnits);
      atMessageListener.messageHandler('12'.codeUnits);
      atMessageListener.messageHandler('34'.codeUnits);
      atMessageListener.messageHandler('56'.codeUnits);
      atMessageListener.messageHandler('78'.codeUnits);
      expect(
          () async =>
              // we want to trigger the maxWaitMilliSeconds exception, so setting transient to a higher value
              await atMessageListener.read(
                  transientWaitTimeMillis: 30, maxWaitMilliSeconds: 20),
          throwsA(predicate((dynamic e) =>
              e is AtTimeoutException &&
              e.message ==
                  'Full response not received after 20 millis from remote secondary')));
    });
    test(
        'A test to verify full response received - delay between messages from server',
        () async {
      String? response;
      unawaited(atMessageListener
          .read(transientWaitTimeMillis: 50)
          .whenComplete(() => {})
          .then((value) => response = value));
      atMessageListener.messageHandler('data:'.codeUnits);
      await Future.delayed(Duration(milliseconds: 25));
      atMessageListener.messageHandler('12'.codeUnits);
      await Future.delayed(Duration(milliseconds: 15));
      atMessageListener.messageHandler('34'.codeUnits);
      await Future.delayed(Duration(milliseconds: 17));
      atMessageListener.messageHandler('56'.codeUnits);
      await Future.delayed(Duration(milliseconds: 30));
      atMessageListener.messageHandler('78'.codeUnits);
      await Future.delayed(Duration(milliseconds: 45));
      atMessageListener.messageHandler('910\n@'.codeUnits);
      await Future.delayed(Duration(milliseconds: 25));
      expect(response, isNotEmpty);
      expect(response, 'data:12345678910');
    });
    test(
        'A test to verify max wait timeout - delay between messages from server',
        () async {
      String? response;
      await atMessageListener
          .read(maxWaitMilliSeconds: 100)
          .catchError((e) {
            return e.toString();
          })
          .whenComplete(() => {})
          .then((value) => {response = value});
      atMessageListener.messageHandler('data:'.codeUnits);
      await Future.delayed(Duration(milliseconds: 15));
      atMessageListener.messageHandler('12'.codeUnits);
      await Future.delayed(Duration(milliseconds: 10));
      atMessageListener.messageHandler('34'.codeUnits);
      await Future.delayed(Duration(milliseconds: 12));
      atMessageListener.messageHandler('56'.codeUnits);
      await Future.delayed(Duration(milliseconds: 13));
      atMessageListener.messageHandler('78'.codeUnits);
      await Future.delayed(Duration(milliseconds: 20));
      atMessageListener.messageHandler('910'.codeUnits);
      await Future.delayed(Duration(milliseconds: 50));
      expect(response, isNotEmpty);
      expect(
        response!.contains(
            'Full response not received after 100 millis from remote secondary'),
        true,
      );
    });
    test(
        'A test to verify transient timeout - delay between messages from server',
        () async {
      String? response;
      await atMessageListener
          .read(transientWaitTimeMillis: 50)
          .catchError((e) {
            return e.toString();
          })
          .whenComplete(() => {})
          .then((value) => {response = value});
      atMessageListener.messageHandler('data:'.codeUnits);
      await Future.delayed(Duration(milliseconds: 10));
      atMessageListener.messageHandler('12'.codeUnits);
      await Future.delayed(Duration(milliseconds: 15));
      atMessageListener.messageHandler('34'.codeUnits);
      await Future.delayed(Duration(milliseconds: 17));
      atMessageListener.messageHandler('56'.codeUnits);
      await Future.delayed(Duration(milliseconds: 20));
      atMessageListener.messageHandler('78'.codeUnits);
      await Future.delayed(Duration(milliseconds: 10));
      atMessageListener.messageHandler('910'.codeUnits);
      await Future.delayed(Duration(milliseconds: 60));
      expect(response, isNotEmpty);
      expect(
        response!.contains('Waited for 50 millis. No response after'),
        true,
      );
    });
  });
}
