import 'registrar_validate_person_response.dart';

abstract interface class RegistrarServiceBase {
  /// Gets a free atSign from the registrar.
  Future<String> getFreeAtSign();

  /// This request is used to register an atSign by assigning it to an email address.
  /// This request accepts an [atSign] and an [email] address.
  /// A one-time password will be sent to the email address provided.
  Future<void> registerPerson({required String atSign, required String email});

  /// This request is used to validate the person registering for an atSign by verifying the one-time password that was
  /// sent to the email address provided. The one-time password is valid for 15 minutes.
  Future<ValidatePersonResponse> validatePerson(
      {required String atSign, required String email, required String otp});

  /// This request is used to check whether the person attempting to activate an atSign is its rightful owner.
  /// The request takes an atSign and sends a one-time password to the email address and/or phone number associated
  /// with that atSign.
  Future<void> authenticateAtSign({required String atSign});

  /// This request is used to check whether the person attempting to activate an atSign is its rightful owner.
  /// The request takes an atSign and a one-time password then provides the cramkey once verified.
  Future<String> authenticateAtSignAndActivate(
      {required String atSign, required String otp});

  /// Weblink to registrar service.
  String get registrarUrlSite;
}
