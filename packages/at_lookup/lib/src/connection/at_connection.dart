import 'dart:async';

abstract class AtConnection<T> {
  /// The underlying connection
  T get underlying;

  /// Metadata for the connection
  final AtConnectionMetaData metaData = AtConnectionMetaData();

  /// The idle timeout in milliseconds (default: 10 minutes)
  int idleTimeMillis = 600000;

  AtConnection() {
    metaData.created = DateTime.now().toUtc();
  }

  /// Writes data to the underlying socket of the connection.
  /// @param - data - Data to write to the socket
  /// @throws [AtIOException] for any exception during the operation
  FutureOr<void> write(String data);

  /// Closes the underlying connection.
  Future<void> close();

  /// Returns true if the connection is invalid.
  bool isInValid() {
    return _isIdle() || metaData.isClosed || metaData.isStale;
  }

  /// Updates the idle time for the connection (Socket or WebSocket).
  void setIdleTime(int? idleTimeMillis) {
    if (idleTimeMillis != null) {
      this.idleTimeMillis = idleTimeMillis;
    }
  }

  /// Checks if the connection has been idle for longer than the specified timeout.
  bool _isIdle() {
    return _getIdleTimeMillis() > idleTimeMillis;
  }

  /// Calculates the idle time in milliseconds.
  int _getIdleTimeMillis() {
    var lastAccessedTime = metaData.lastAccessed;
    lastAccessedTime ??= metaData.created;
    var currentTime = DateTime.now().toUtc();
    return currentTime.difference(lastAccessedTime!).inMilliseconds;
  }
}

/// Metadata for [AtConnection].
class AtConnectionMetaData {
  bool isAuthenticated = false;
  DateTime? lastAccessed;
  DateTime? created;
  bool isClosed = false;
  bool isStale = false;
}
