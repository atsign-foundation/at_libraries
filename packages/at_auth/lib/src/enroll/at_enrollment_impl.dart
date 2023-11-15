import 'dart:async';
import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_builders.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_utils/at_logger.dart';
import 'package:crypton/crypton.dart';
import 'package:meta/meta.dart';

/// A concrete implementation of [AtEnrollmentBase] for managing enrollments.
///
/// This class provides functionality to submit and manage enrollment requests.
class AtEnrollmentImpl implements AtEnrollmentBase {
  final AtSignLogger _logger = AtSignLogger('AtEnrollmentServiceImpl');
  final String _atSign;

  AtEnrollmentImpl(this._atSign);

  @override
  Future<AtEnrollmentResponse> submitEnrollment(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) async {
    _logger.info('Generating APKAM encryption keypair and APKAM symmetric key');
    AtPkamKeyPair atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
    SymmetricKey apkamSymmetricKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);

    return await enrollInternal(
        atEnrollmentRequest, atLookUp, atPkamKeyPair, apkamSymmetricKey);
  }

  @visibleForTesting
  Future<AtEnrollmentResponse> enrollInternal(
      AtEnrollmentRequest atEnrollmentRequest,
      AtLookUp atLookUp,
      AtPkamKeyPair atPkamKeyPair,
      SymmetricKey apkamSymmetricKey) async {
    String defaultEncryptionPublicKey =
        await _getDefaultEncryptionPublicKey(atLookUp);
    // Encrypting the Encryption Public key with APKAM Symmetric key.
    String encryptedApkamSymmetricKey =
        RSAPublicKey.fromString(defaultEncryptionPublicKey)
            .encrypt(apkamSymmetricKey.key);

    EnrollResponse enrollmentResponse = await _sendEnrollmentRequest(
      atLookUp,
      atEnrollmentRequest.appName,
      atEnrollmentRequest.deviceName,
      atEnrollmentRequest.otp,
      atEnrollmentRequest.namespaces,
      atPkamKeyPair.atPublicKey.publicKey,
      encryptedApkamSymmetricKey,
    );

    AtChopsKeys atChopsKeys = AtChopsKeys.create(
        AtEncryptionKeyPair.create(defaultEncryptionPublicKey, ''),
        AtPkamKeyPair.create(atPkamKeyPair.atPublicKey.publicKey,
            atPkamKeyPair.atPrivateKey.privateKey));
    atChopsKeys.apkamSymmetricKey = apkamSymmetricKey;

    atLookUp.atChops = AtChopsImpl(atChopsKeys);
    AtAuthKeys atAuthKeys = AtAuthKeys()
      ..apkamPrivateKey = atPkamKeyPair.atPrivateKey.privateKey
      ..apkamPublicKey = atPkamKeyPair.atPublicKey.publicKey
      ..defaultEncryptionPublicKey = defaultEncryptionPublicKey
      ..apkamSymmetricKey = apkamSymmetricKey.key
      ..enrollmentId = enrollmentResponse.enrollmentId;

    // The EnrollmentSubmissionResponse has atChopsKeys which contains the APKAM
    // keys and APKAM Symmetric key which will be persisted by the client requesting the
    // enrollment.
    AtEnrollmentResponse atEnrollmentResponse = AtEnrollmentResponse(
        enrollmentResponse.enrollmentId, enrollmentResponse.enrollStatus);
    atEnrollmentResponse.atAuthKeys = atAuthKeys;
    return atEnrollmentResponse;
  }

  Future<String> _getDefaultEncryptionPublicKey(AtLookUp atLookupImpl) async {
    var lookupVerbBuilder = LookupVerbBuilder()
      ..atKey = 'publickey'
      ..sharedBy = _atSign;
    String? lookupResult = await atLookupImpl.executeVerb(lookupVerbBuilder);
    if (lookupResult == null || lookupResult.isEmpty) {
      throw AtEnrollmentException(
          'Unable to lookup encryption public key. Server response is null/empty');
    }
    var defaultEncryptionPublicKey = lookupResult.replaceFirst('data:', '');
    return defaultEncryptionPublicKey;
  }

  Future<EnrollResponse> _sendEnrollmentRequest(
    AtLookUp atLookUp,
    String? appName,
    String? deviceName,
    String? otp,
    Map<String, String>? namespaces,
    String apkamPublicKey,
    String encryptedApkamSymmetricKey,
  ) async {
    var enrollVerbBuilder = EnrollVerbBuilder()
      ..appName = appName
      ..deviceName = deviceName
      ..namespaces = namespaces
      ..otp = otp
      ..apkamPublicKey = apkamPublicKey
      ..encryptedAPKAMSymmetricKey = encryptedApkamSymmetricKey;
    var enrollResult =
        await atLookUp.executeCommand(enrollVerbBuilder.buildCommand());
    if (enrollResult == null ||
        enrollResult.isEmpty ||
        enrollResult.startsWith('error:')) {
      throw AtEnrollmentException(
          'Enrollment response from server: $enrollResult');
    }
    enrollResult = enrollResult.replaceFirst('data:', '');
    var enrollJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollJson[AtConstants.enrollmentId];

    return EnrollResponse(enrollmentIdFromServer,
        getEnrollStatusFromString(enrollJson['status']));
  }

  @override
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) {
    switch (atEnrollmentRequest.enrollOperationEnum) {
      case EnrollOperationEnum.approve:
        return _handleApproveOperation(atEnrollmentRequest, atLookUp);
      case EnrollOperationEnum.deny:
        return _handleDenyOperation(atEnrollmentRequest, atLookUp);
      default:
        throw AtEnrollmentException('Enrollment operation is not provided');
    }
  }

  Future<AtEnrollmentResponse> _handleApproveOperation(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) async {
    // Decrypt the encrypted APKAM Symmetric key
    var defaultEncryptionPrivateKey = RSAPrivateKey.fromString(atLookUp
        .atChops!.atChopsKeys.atEncryptionKeyPair!.atPrivateKey.privateKey);
    var apkamSymmetricKey = defaultEncryptionPrivateKey
        .decrypt(atEnrollmentRequest.encryptedAPKAMSymmetricKey!);
    atLookUp.atChops?.atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);

    String command = 'enroll:approve:${jsonEncode({
          'enrollmentId': atEnrollmentRequest.enrollmentId,
          'encryptedDefaultEncryptedPrivateKey': atLookUp.atChops
              ?.encryptString(
                  atLookUp.atChops!.atChopsKeys.atEncryptionKeyPair!
                      .atPrivateKey.privateKey,
                  EncryptionKeyType.aes256,
                  keyName: 'apkamSymmetricKey',
                  iv: AtChopsUtil.generateIVLegacy())
              .result,
          'encryptedDefaultSelfEncryptionKey': atLookUp.atChops
              ?.encryptString(
                  atLookUp.atChops!.atChopsKeys.selfEncryptionKey!.key,
                  EncryptionKeyType.aes256,
                  keyName: 'apkamSymmetricKey',
                  iv: AtChopsUtil.generateIVLegacy())
              .result
        })}';

    String? enrollResponse =
        await atLookUp.executeCommand('$command\n', auth: true);
    enrollResponse = enrollResponse?.replaceAll('data:', '');
    var enrollmentJsonMap = jsonDecode(enrollResponse!);
    AtEnrollmentResponse enrollmentResponse = AtEnrollmentResponse(
        enrollmentJsonMap['enrollmentId'],
        _convertEnrollmentStatusToEnum(enrollmentJsonMap['status']));
    return enrollmentResponse;
  }

  _convertEnrollmentStatusToEnum(String enrollmentStatus) {
    switch (enrollmentStatus) {
      case 'approved':
        return EnrollStatus.approved;
      case 'denied:':
        return EnrollStatus.denied;
      case 'expired':
        return EnrollStatus.expired;
      case 'revoked':
        return EnrollStatus.revoked;
      case 'pending':
        return EnrollStatus.pending;
      default:
        throw AtEnrollmentException(
            '$enrollmentStatus is not a valid enrollment status');
    }
  }

  Future<AtEnrollmentResponse> _handleDenyOperation(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) async {
    String command =
        'enroll:deny:enrollmentId:${atEnrollmentRequest.enrollmentId}';
    String? enrollResponse =
        await atLookUp.executeCommand('$command\n', auth: true);
    enrollResponse = enrollResponse?.replaceAll('data:', '');
    var enrollmentJsonMap = jsonDecode(enrollResponse!);
    AtEnrollmentResponse enrollmentResponse = AtEnrollmentResponse(
        enrollmentJsonMap['enrollmentId'], enrollmentJsonMap['status']);
    return enrollmentResponse;
  }
}
