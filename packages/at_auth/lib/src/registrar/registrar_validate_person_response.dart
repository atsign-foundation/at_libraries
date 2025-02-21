import 'registrar_exception.dart';

class ValidatePersonResponse {
  const ValidatePersonResponse({
    this.existingAtSigns = const [],
    this.errorMessage,
    this.cramKey,
    this.newAtSign,
  });

  final List<String> existingAtSigns;
  final String? errorMessage;
  final String? cramKey;
  final String? newAtSign;

  factory ValidatePersonResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('success') && json['success'] == true) {
      final data = (json['cramKey'] as String?)?.split(':');
      final atsign = data?[0];
      final cramKey = data?[1];
      return ValidatePersonResponse(
        cramKey: cramKey,
        newAtSign: atsign,
      );
    }

    // If message is present and not null then it means it's an error
    if (json.containsKey('message') && json['message'] != null) {
      return ValidatePersonResponse(
        errorMessage: json['message'] as String?,
      );
    }

    if (json.containsKey('data') &&
        json['data'] != null &&
        (json['data'] as Map<String, dynamic>).isNotEmpty) {
      final data = json['data'] as Map<String, dynamic>;
      final atSigns = (data['atsigns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];
      final newAtSign = data['newAtsign'] as String?;

      return ValidatePersonResponse(
        existingAtSigns: atSigns,
        newAtSign: newAtSign,
      );
    }

    if (json.containsKey('status') && json['status'] == "error") {
      return ValidatePersonResponse(
        errorMessage: json['message'] as String?,
      );
    }

    throw RegistrarException(
      error: 'Invalid response format',
      message: 'Unexpected response structure: $json',
    );
  }

  bool get success => newAtSign != null || cramKey != null;
}
