import 'dart:io';
import 'package:at_commons/at_commons.dart';
abstract class OutboundConnection extends BaseConnection {
  OutboundConnection(Socket socket) : super(socket);
  void setIdleTime(int? idleTimeMillis);
}

/// Metadata information for [OutboundConnection]
class OutboundConnectionMetadata extends AtConnectionMetaData {}
