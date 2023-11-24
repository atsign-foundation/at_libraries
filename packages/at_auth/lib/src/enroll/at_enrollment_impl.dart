import 'dart:async';
import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_auth/src/enroll/at_enrollment_notification_request.dart';
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
    switch (atEnrollmentRequest.runtimeType) {
      case AtInitialEnrollmentRequest:
        return await initialClientEnrollment(
            atEnrollmentRequest as AtInitialEnrollmentRequest, atLookUp);
      case AtNewEnrollmentRequest:
        return await newClientEnrollment(
            atEnrollmentRequest as AtNewEnrollmentRequest, atLookUp);
      default:
        throw AtEnrollmentException(
            'Invalid AtEnrollmentRequest type: ${atEnrollmentRequest.runtimeType}');
    }
  }

  @visibleForTesting
  Future<AtEnrollmentResponse> initialClientEnrollment(
      AtInitialEnrollmentRequest atInitialEnrollmentRequest,
      AtLookUp atLookUp) async {
    _logger.finer('inside initialClientEnrollment');
    final atAuthKeys = atInitialEnrollmentRequest.atAuthKeys;
    var enrollVerbBuilder = createEnrollVerbBuilder(atInitialEnrollmentRequest);
    var enrollResult = await _executeEnrollCommand(enrollVerbBuilder, atLookUp);
    _logger.finer('enrollResult: $enrollResult');
    var enrollJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollJson[AtConstants.enrollmentId];
    var enrollStatus = getEnrollStatusFromString(enrollJson['status']);
    atAuthKeys!.enrollmentId = enrollmentIdFromServer;
    return AtEnrollmentResponse(enrollmentIdFromServer, enrollStatus)
      ..atAuthKeys = atAuthKeys;
  }

  @visibleForTesting
  Future<AtEnrollmentResponse> newClientEnrollment(
      AtNewEnrollmentRequest atNewEnrollmentRequest, AtLookUp atLookUp) async {
    _logger.info('Generating APKAM encryption keypair and APKAM symmetric key');
    AtPkamKeyPair atPkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
    SymmetricKey apkamSymmetricKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    // default flow
    String defaultEncryptionPublicKey =
        await _getDefaultEncryptionPublicKey(atLookUp);
    // Encrypting the Encryption Public key with APKAM Symmetric key.
    String encryptedApkamSymmetricKey =
        RSAPublicKey.fromString(defaultEncryptionPublicKey)
            .encrypt(apkamSymmetricKey.key);
    var enrollVerbBuilder = createEnrollVerbBuilder(atNewEnrollmentRequest,
        atPkamKeyPair: atPkamKeyPair,
        encryptedApkamSymmetricKey: encryptedApkamSymmetricKey);
    var enrollResult = await _executeEnrollCommand(enrollVerbBuilder, atLookUp);
    var enrollJson = jsonDecode(enrollResult);
    var enrollmentIdFromServer = enrollJson[AtConstants.enrollmentId];
    var enrollStatus = getEnrollStatusFromString(enrollJson['status']);
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
      ..enrollmentId = enrollmentIdFromServer;

    AtEnrollmentResponse atEnrollmentResponse =
        AtEnrollmentResponse(enrollmentIdFromServer, enrollStatus);
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

  @override
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) {
    switch (atEnrollmentRequest.enrollOperationEnum) {
      case EnrollOperationEnum.approve:
        return _handleApproveOperation(
            atEnrollmentRequest as AtEnrollmentNotificationRequest, atLookUp);
      case EnrollOperationEnum.deny:
        return _handleDenyOperation(atEnrollmentRequest, atLookUp);
      default:
        throw AtEnrollmentException('Enrollment operation is not provided');
    }
  }

  Future<AtEnrollmentResponse> _handleApproveOperation(
      AtEnrollmentNotificationRequest atEnrollmentNotificationRequest,
      AtLookUp atLookUp) async {
    // Decrypt the encrypted APKAM Symmetric key
    var defaultEncryptionPrivateKey = RSAPrivateKey.fromString(atLookUp
        .atChops!.atChopsKeys.atEncryptionKeyPair!.atPrivateKey.privateKey);
    var apkamSymmetricKey = defaultEncryptionPrivateKey
        .decrypt(atEnrollmentNotificationRequest.encryptedApkamSymmetricKey);
    atLookUp.atChops?.atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);

    String command = 'enroll:approve:${jsonEncode({
          'enrollmentId': atEnrollmentNotificationRequest.enrollmentId,
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

  @visibleForTesting
  EnrollVerbBuilder createEnrollVerbBuilder(
    AtEnrollmentRequest request, {
    AtPkamKeyPair? atPkamKeyPair,
    String? encryptedApkamSymmetricKey,
  }) {
    var enrollVerbBuilder = EnrollVerbBuilder()
      ..appName = request.appName
      ..deviceName = request.deviceName
      ..namespaces = request.namespaces;

    if (request is AtInitialEnrollmentRequest) {
      enrollVerbBuilder
        ..encryptedDefaultEncryptionPrivateKey =
            request.encryptedDefaultEncryptionPrivateKey
        ..encryptedDefaultSelfEncryptionKey =
            request.encryptedDefaultSelfEncryptionKey
        ..apkamPublicKey = request.apkamPublicKey;
    } else if (request is AtNewEnrollmentRequest) {
      enrollVerbBuilder
        ..otp = request.otp
        ..apkamPublicKey = atPkamKeyPair!.atPublicKey.publicKey
        ..encryptedAPKAMSymmetricKey = encryptedApkamSymmetricKey;
    }

    return enrollVerbBuilder;
  }

  Future<String> _executeEnrollCommand(
      EnrollVerbBuilder enrollVerbBuilder, AtLookUp atLookUp) async {
    var enrollResult =
        await atLookUp.executeCommand(enrollVerbBuilder.buildCommand());
    if (enrollResult == null ||
        enrollResult.isEmpty ||
        enrollResult.startsWith('error:')) {
      throw AtEnrollmentException(
          'Enrollment response from server: $enrollResult');
    }
    return enrollResult.replaceFirst('data:', '');
  }
}
