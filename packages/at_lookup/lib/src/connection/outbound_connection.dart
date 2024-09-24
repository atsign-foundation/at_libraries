import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/base_connection.dart';

/// Abstract class to handle both Socket and WebSocket connections
abstract class OutboundConnection extends BaseConnection {
  /// Constructor that can handle either a Socket or a WebSocket
  OutboundConnection(dynamic connection) : super(connection);

  /// Set idle time for the connection (you may handle socket or websocket specifically here if needed)
  void setIdleTime(int? idleTimeMillis);
}

/// Metadata information for [OutboundConnection]
class OutboundConnectionMetadata extends AtConnectionMetaData {}

