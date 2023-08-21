import 'package:at_commons/src/exception/at_exceptions.dart';

class AtServerException extends AtException {
  AtServerException(message) : super(message);
}

/// Thrown when current server's inbound connection limit is reached
class InboundConnectionLimitException extends AtServerException {
  InboundConnectionLimitException(message) : super(message);
}

/// Thrown when current server's outbound connection limit is reached
class OutboundConnectionLimitException extends AtServerException {
  OutboundConnectionLimitException(message) : super(message);
}

class BlockedConnectionException extends AtServerException {
  BlockedConnectionException(message) : super(message);
}

/// Thrown when lookup fails after handshake
class LookupException extends AtServerException {
  LookupException(message) : super(message);
}

/// Thrown for any unhandled server exception
class InternalServerException extends AtServerException {
  InternalServerException(message) : super(message);
}

/// Thrown for any unhandled server error
class InternalServerError extends AtServerException {
  InternalServerError(message) : super(message);
}

/// Thrown when a request is received on a connection while the server is paused
class ServerIsPausedException extends AtServerException {
  ServerIsPausedException(message) : super(message);
}

/// When enrollment request for an enrollment id has been denied/revoked
/// If that enrollment id is used to attempt authentication this exception is thrown
class ApkamAuthDenied extends AtServerException {
  ApkamAuthDenied(message) : super(message);
}

class ApkamAuthFailed extends AtServerException {
  ApkamAuthFailed(message) : super(message);
}

class ApkamAccessRevoked extends AtServerException {
  ApkamAccessRevoked(message) : super(message);
}
