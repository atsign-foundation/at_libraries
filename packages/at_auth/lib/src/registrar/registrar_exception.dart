class RegistrarException implements Exception {
  RegistrarException({required this.error, required this.message});

  /// Error message. Internal use only.
  final String error;

  /// Helpful message to display to end-user.
  final String message;

  @override
  String toString() => 'RegistrarException - Error: $error, Message: $message';
}
