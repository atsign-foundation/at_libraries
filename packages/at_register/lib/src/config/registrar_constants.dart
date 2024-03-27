class RegistrarConstants {
  /// Authorities
  static const String apiHostProd = 'my.atsign.com';
  static const String apiHostStaging = 'my.atsign.wtf';

  /// Select [Prod/Staging]
  /// Change to [apiHostStaging] to use AtRegister in a staging env
  static const String authority = apiHostProd;

  /// API Paths
  static const String getFreeAtSignApiPath = '/api/app/v3/get-free-atsign';
  static const String registerAtSignApiPath = '/api/app/v3/register-person';
  static const String validateOtpApiPath = '/api/app/v3/validate-person';
  static const String requestAuthenticationOtpPath =
      '/api/app/v3/authenticate/atsign';
  static const String getCramKeyWithOtpPath =
      '/api/app/v3/authenticate/atsign/activate';

  /// API headers
  static const String contentType = 'application/json';
  static const String authorization = '477b-876u-bcez-c42z-6a3d';

  /// DebugMode: setting it to true will print more logs to aid understanding
  /// the inner working of Register_cli
  static const bool isDebugMode = true;

  static const String cramKeyName = 'cramkey';
  static const String atsignName = 'atsign';
  static const String otpSentName = 'otpSent';
  static const String fetchedAtsignListName = 'fetchedAtsignList';
  static const String newAtsignName = 'newAtsign';
}
