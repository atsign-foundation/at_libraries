import 'dart:io';
/// Abstract class for a general connection
abstract class AtConnection {
  /// Write data to the underlying connection
  void write(String data);

  /// Retrieves the underlying connection (Socket or WebSocket)
  dynamic getSocket();

  /// Closes the connection
  Future<void> close();

  /// Returns true if the connection is invalid
  bool isInValid();

  /// Retrieves connection metadata
  AtConnectionMetaData? getMetaData();
}

/// Abstract class for Socket-based connections
abstract class SocketConnection extends AtConnection {
  /// Get the underlying Socket
  @override
  Socket getSocket();
}

/// Abstract class for WebSocket-based connections
abstract class WebSocketConnection extends AtConnection {
  /// Get the underlying WebSocket
  WebSocket getWebSocket();
}


abstract class AtConnectionMetaData {
  bool isAuthenticated = false;
  DateTime? lastAccessed;
  DateTime? created;
  bool isClosed = false;
  bool isStale = false;
}
