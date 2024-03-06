/// Class representing an enrollment notification received from the server.
class EnrollmentServerResponse {
  late String appName;
  late String deviceName;
  late Map<String, String> namespace;
  late String encryptedAPKAMSymmetricKey;
}