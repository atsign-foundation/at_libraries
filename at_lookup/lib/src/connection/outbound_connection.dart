import 'dart:io';
import 'package:at_lookup/src/connection/at_connection.dart';
import 'package:at_lookup/src/connection/base_connection.dart';

abstract class OutboundConnection extends BaseConnection {
  OutboundConnection(Socket socket) : super(socket);
  void setIdleTime(int idleTimeMillis);
}

/// Metadata information for [OutboundConnection]
class OutboundConnectionMetadata extends AtConnectionMetaData {}
