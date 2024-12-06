import 'dart:async';
import 'dart:io';

import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/at_message_listener.dart';
import 'package:at_lookup/src/connection/at_socket_connection.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'at_lookup_test_utils.dart';

class MockAtLookupSecureSocketFactory extends Mock
    implements AtLookupSecureSocketFactory {}

void main() {
  group('test connection close and socket cleanup', () {
    late SecondaryAddressFinder finder;
    late MockAtLookupConnectionFactory mockAtConnectionFactory;
    late AtMessageListener mockAtMessageListener;

    setUp(() {
      mockSocketNumber = 1; // Reset counter for each test
      finder = MockSecondaryAddressFinder();
      when(() => finder.findSecondary(any()))
          .thenAnswer((_) async => SecondaryAddress('test.test.test', 12345));

      mockAtConnectionFactory = MockAtLookupConnectionFactory();
      registerFallbackValue(SecureSocketConfig());

      mockAtMessageListener = MockAtMessageListener();

      when(() => mockAtConnectionFactory.createUnderlying(
          'test.test.test', '12345', any())).thenAnswer((_) {
        // Each call provides a new instance of MockSecureSocket
        SecureSocket newMockSocket =
            createMockAtServerSocket('test.test.test', 12345);
        AtSocketConnection atConnection = AtSocketConnection(newMockSocket);

        // Update factory to return this new connection and listener
        when(() =>
                mockAtConnectionFactory.createConnection(newMockSocket))
            .thenReturn(atConnection);

        when(() => mockAtConnectionFactory.createListener(atConnection))
            .thenAnswer((_) => mockAtMessageListener);
        return Future<SecureSocket>.value(newMockSocket);
      });
    });

    test(
        'test AtLookupImpl will use its default SecureSocketFactory if none is provided to it',
        () async {
      AtLookupImpl atLookup = AtLookupImpl('@alice', 'test.test.test', 64,
          secondaryAddressFinder: finder);

      expect(atLookup.atConnectionFactory.runtimeType.toString(),
          "AtLookupSecureSocketFactory");
      expect(() async => await atLookup.createConnection(),
          throwsA(predicate((dynamic e) => e is SecondaryConnectException)));
    });

    test(
        'A test to verify the connections are invalidated after the connection time-outs',
        () async {
      String host = 'test.host';
      int port = 64;

      SecureSocket mockSecureSocket = MockSecureSocket();
      MockAtLookupSecureSocketFactory mockAtLookupSecureSocketFactory =
          MockAtLookupSecureSocketFactory();
      SecondaryAddressFinder mockSecondaryAddressFinder =
          MockSecondaryAddressFinder();

      AtLookupImpl atLookup = AtLookupImpl('@alice', host, port,
          secondaryAddressFinder: mockSecondaryAddressFinder);
      SecureSocketConfig secureSocketConfig = SecureSocketConfig();

      // Setting mock instances
      atLookup.atConnectionFactory = mockAtLookupSecureSocketFactory;

      // Set mock responses.
      when(() => mockAtLookupSecureSocketFactory.createUnderlying(
              host, '$port', secureSocketConfig))
          .thenAnswer((_) => Future.value(mockSecureSocket));

      when(() => mockSecureSocket.setOption(SocketOption.tcpNoDelay, true))
          .thenReturn(true);

      // In the constructor of [AtSocketConnection] which is super class of AtConnection
      // socket.setOption is invoked. Therefore, the initialization of AtSocketConnection
      // should be executed after when(() => mockSecureSocket.setOption).
      // Otherwise a null exception arises.
      AtSocketConnection atConnection = AtSocketConnection(mockSecureSocket);

      when(() => mockAtLookupSecureSocketFactory
          .createConnection(mockSecureSocket)).thenReturn(atConnection);

      when(() => mockAtLookupSecureSocketFactory.createListener(atConnection))
          .thenReturn(AtMessageListener(atConnection));

      // Setting connection timeout to 2 seconds.
      atLookup.atConnectionTimeout = Duration(seconds: 2).inMilliseconds;
      // Create connection.
      bool isConnCreated =
          await atLookup.createAtConnection(host, '$port', secureSocketConfig);
      expect(isConnCreated, true);
      expect(atLookup.connection?.isInValid(), false);
      // Wait for the connection to timeout.
      await Future.delayed(Duration(seconds: 2));
      expect(atLookup.connection?.isInValid(), true);
    });

    test(
        'test AtLookupImpl closes invalid connections before creating new ones',
        () async {
      AtLookupImpl atLookup = AtLookupImpl('@alice', 'test.test.test', 64,
          secondaryAddressFinder: finder);
      expect(atLookup.atConnectionFactory.runtimeType.toString(),
          "AtLookupSecureSocketFactory");

      // Override atConnectionFactory with mock in AtLookupImpl
      atLookup.atConnectionFactory = mockAtConnectionFactory;

      await atLookup.createConnection();

      // let's get a handle to the first socket & connection
      AtSocketConnection firstConnection =
          atLookup.connection as AtSocketConnection; // Explicit cast
      MockSecureSocket firstSocket =
          firstConnection.underlying as MockSecureSocket;

      expect(firstSocket.mockNumber, 1);
      expect(firstSocket.destroyed, false);
      expect(firstConnection.metaData.isClosed, false);
      expect(firstConnection.isInValid(), false);

      // Make the connection appear 'idle'
      firstConnection.setIdleTime(1);
      await Future.delayed(Duration(milliseconds: 2));
      expect(firstConnection.isInValid(), true);

      atLookup.atConnectionFactory = mockAtConnectionFactory;

      // When we now call AtLookupImpl's createConnection again, it should:
      // - notice that its current connection is 'idle', and close it
      // - create a new connection
      await atLookup.createConnection();

      // has the first connection been closed, and its socket destroyed?
      expect(firstSocket.destroyed, true);
      expect(firstConnection.metaData.isClosed, true);

      // has a new connection been created, with a new socket?
      AtSocketConnection secondConnection =
          atLookup.connection as AtSocketConnection; // Explicit cast
      MockSecureSocket secondSocket =
          secondConnection.underlying as MockSecureSocket;
      expect(firstConnection.hashCode == secondConnection.hashCode, false);
      expect(secondSocket.mockNumber, 2);
      expect(secondSocket.destroyed, false);
      expect(secondConnection.metaData.isClosed, false);
      expect(secondConnection.isInValid(), false);
    });

    test(
        'test message listener closes connection'
        ' when socket listener onDone is called', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, false);
      oml.onSocketDone();
      expect((oc.underlying as MockSecureSocket).destroyed, true);
      expect(oc.metaData.isClosed, true);
    });

    test(
        'test message listener closes connection'
        ' when socket listener onError is called', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, false);
      oml.onSocketError('test');
      expect((oc.underlying as MockSecureSocket).destroyed, true);
      expect(oc.metaData.isClosed, true);
    });

    test('test can safely call connection.close() repeatedly', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, false);
      await oml.closeConnection();
      expect((oc.underlying as MockSecureSocket).destroyed, true);
      expect(oc.metaData.isClosed, true);

      (oc.underlying as MockSecureSocket).destroyed = false;
      await oml.closeConnection();
      // Since the connection was already closed above,
      // we don't expect destroy to be called on the socket again
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, true);
    });

    test(
        'test that AtMessageListener.closeConnection will call'
        ' connection.close if the connection is idle', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, false);

      expect(oc.isInValid(), false);
      // Make the connection appear 'idle'
      oc.setIdleTime(1);
      await Future.delayed(Duration(milliseconds: 2));
      expect(oc.isInValid(), true);

      await oml.closeConnection();

      expect((oc.underlying as MockSecureSocket).destroyed, true);
      expect(oc.metaData.isClosed, true);
    });

    test(
        'test that AtMessageListener.closeConnection will not call'
        ' connection.close if already marked closed', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      oc.metaData.isClosed = true;

      await oml.closeConnection();

      // socketDestroyed will be set in these tests only if socket.destroy() is called
      expect((oc.underlying as MockSecureSocket).destroyed, false);
    });

    test(
        'test that AtMessageListener.closeConnection will call'
        ' connection.close even if the connection is marked stale', () async {
      AtConnection oc =
          AtSocketConnection(createMockAtServerSocket('test.test.test', 12345));
      AtMessageListener oml = AtMessageListener(oc);
      expect((oc.underlying as MockSecureSocket).destroyed, false);
      expect(oc.metaData.isClosed, false);
      oc.metaData.isStale = true;

      await oml.closeConnection();

      expect((oc.underlying as MockSecureSocket).destroyed, true);
      expect(oc.metaData.isClosed, true);
    });
  });

  // In order to reduce duplicated test code, creating test functions which will be used in two ways. See test groups below.
  testOne(Duration? delayBeforeClose) async {
    Socket mockSocket = MockSecureSocket();
    when(() => mockSocket.setOption(SocketOption.tcpNoDelay, true))
        .thenAnswer((_) => true);
    AtConnection connection = AtSocketConnection(mockSocket);
    AtMessageListener atMessageListener = AtMessageListener(connection);

    // We want to set up a connection, then call read() and have it time out.
    // When read() times out, the connection should be closed BEFORE the exception is thrown
    // This test is to guard against race conditions if we're not using `await` somewhere that we should be

    // This variable enables us to introduce a delay before closing the connection
    // The introduction of this delay enables the race condition (if it exists) to occur in this test
    if (delayBeforeClose != null) {
      atMessageListener.delayBeforeClose = delayBeforeClose;
    }
    int transientWaitTimeMillis = 50;
    try {
      await atMessageListener.read(
          transientWaitTimeMillis: transientWaitTimeMillis);
    } on AtTimeoutException catch (expected) {
      expect(
          expected.message,
          startsWith(
              'Waited for $transientWaitTimeMillis millis. No response after'));
      expect(connection.isInValid(), true);
    }
  }

  testTwo(Duration? delayBeforeClose) async {
    Socket mockSocket = MockSecureSocket();
    when(() => mockSocket.setOption(SocketOption.tcpNoDelay, true))
        .thenAnswer((_) => true);
    AtConnection connection = AtSocketConnection(mockSocket);
    AtMessageListener atMessageListener = AtMessageListener(connection);

    // We want to set up a connection, then call read() and have it time out.
    // When read() times out, the connection should be closed BEFORE the exception is thrown
    // This test is to guard against race conditions if we're not using `await` somewhere that we should be

    // This variable enables us to introduce a delay before closing the connection
    // The introduction of this delay enables the race condition (if it exists) to occur in this test
    if (delayBeforeClose != null) {
      atMessageListener.delayBeforeClose = delayBeforeClose;
    }
    int maxWaitMilliSeconds = 50;
    try {
      await atMessageListener.read(maxWaitMilliSeconds: maxWaitMilliSeconds);
      expect(false, true, reason: 'Test should not have reached this point');
    } on AtTimeoutException catch (expected) {
      expect(expected.message,
          'Full response not received after $maxWaitMilliSeconds millis from remote secondary');
      expect(connection.isInValid(), true);
    }
  }

  testThree(Duration? delayBeforeClose) async {
    Socket mockSocket = MockSecureSocket();
    when(() => mockSocket.setOption(SocketOption.tcpNoDelay, true))
        .thenAnswer((_) => true);
    AtConnection connection = AtSocketConnection(mockSocket);
    AtMessageListener atMessageListener = AtMessageListener(connection);

    // We want to set up a connection, then call read() and have it time out.
    // When read() times out, the connection should be closed BEFORE the exception is thrown
    // This test is to guard against race conditions if we're not using `await` somewhere that we should be

    // This variable enables us to introduce a delay before closing the connection
    // The introduction of this delay enables the race condition (if it exists) to occur in this test
    if (delayBeforeClose != null) {
      atMessageListener.delayBeforeClose = delayBeforeClose;
    }
    int maxWaitMilliSeconds = 50;
    try {
      await atMessageListener.read(maxWaitMilliSeconds: maxWaitMilliSeconds);
      expect(false, true, reason: 'Test should not have reached this point');
    } on AtTimeoutException catch (expected) {
      expect(expected.message,
          'Full response not received after $maxWaitMilliSeconds millis from remote secondary');
      expect(() async => await connection.write("hello\n"),
          throwsA(predicate((dynamic e) => e is ConnectionInvalidException)));
    }
  }

  group('A group of tests to detect race condition in connection management',
      () {
    test(
        'Test that isInvalid is set on the AtConnection after transientWaitTime timeout BEFORE the AtMessageListener.read() returns',
        () async {
      await testOne(Duration(milliseconds: 100));
    });

    test(
        'Test that isInvalid is set on the AtConnection after maxWaitTime timeout BEFORE the AtMessageListener.read() returns',
        () async {
      await testTwo(Duration(milliseconds: 100));
    });

    test(
        'Test that an attempt to write to an AtConnection which has had a timeout will throw a ConnectionInvalidException',
        () async {
      await testThree(Duration(milliseconds: 100));
    });
  });

  /// These tests will pass even when the race condition exists because of complications in the event loop from testing
  /// The tests are here to verify that we haven't caused another problem from the introduction
  /// of `@visibleForTesting Duration? delayBeforeClose` into AtMessageListener
  group('Same race condition tests without the artificial delay', () {
    test(
        'Test that isInvalid is set on the AtConnection after transientWaitTime timeout BEFORE the AtMessageListener.read() returns',
        () async {
      await testOne(null);
    });

    test(
        'Test that isInvalid is set on the AtConnection after maxWaitTime timeout BEFORE the AtMessageListener.read() returns',
        () async {
      await testTwo(null);
    });

    test(
        'Test that an attempt to write to an AtConnection which has had a timeout will throw a ConnectionInvalidException',
        () async {
      await testThree(null);
    });
  });
}
