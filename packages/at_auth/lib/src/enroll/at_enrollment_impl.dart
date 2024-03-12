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
  Future<AtEnrollmentResponse> submit(
      BaseEnrollmentRequest baseEnrollmentRequest, AtLookUp atLookUp) async {
    switch (baseEnrollmentRequest) {
      case FirstEnrollmentRequest _:
        return _handleFirstEnrollmentRequest(baseEnrollmentRequest, atLookUp);
      case EnrollmentRequest _:
        return _handleEnrollmentRequest(baseEnrollmentRequest, atLookUp);
      default:
        throw InvalidRequestException('Invalid Enrollment request received');
    }
  }

  /// Handles the FirstEnrollmentRequest, which is submitted when an atSign is first onboarded.
  Future<AtEnrollmentResponse> _handleFirstEnrollmentRequest(
      FirstEnrollmentRequest baseEnrollmentRequest, AtLookUp atLookUp) async {
    EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
      ..appName = baseEnrollmentRequest.appName
      ..deviceName = baseEnrollmentRequest.deviceName;
    enrollVerbBuilder.apkamPublicKey = baseEnrollmentRequest.apkamPublicKey;
    enrollVerbBuilder.encryptedDefaultEncryptionPrivateKey =
        baseEnrollmentRequest.encryptedDefaultEncryptionPrivateKey;
    enrollVerbBuilder.encryptedDefaultSelfEncryptionKey =
        baseEnrollmentRequest.encryptedDefaultSelfEncryptionKey;

    String? serverResponse =
        await _executeEnrollCommand(enrollVerbBuilder, atLookUp);
    var enrollJson = jsonDecode(serverResponse);
    var enrollmentIdFromServer = enrollJson[AtConstants.enrollmentId];
    var enrollStatus = getEnrollStatusFromString(enrollJson['status']);

    return AtEnrollmentResponse(enrollmentIdFromServer, enrollStatus);
  }

  /// Handles the subsequent enrollment requests.
  Future<AtEnrollmentResponse> _handleEnrollmentRequest(
      EnrollmentRequest enrollmentRequest, AtLookUp atLookUp) async {
    EnrollVerbBuilder enrollVerbBuilder = EnrollVerbBuilder()
      ..appName = enrollmentRequest.appName
      ..deviceName = enrollmentRequest.deviceName;

    // Generate APKAM Key pair
    AtPkamKeyPair apkamKeyPair = AtChopsUtil.generateAtPkamKeyPair();
    enrollVerbBuilder.apkamPublicKey = apkamKeyPair.atPublicKey.publicKey;
    SymmetricKey apkamSymmetricKey =
        AtChopsUtil.generateSymmetricKey(EncryptionKeyType.aes256);
    String defaultEncryptionPublicKey =
        await _getDefaultEncryptionPublicKey(atLookUp);
    // Encrypting the Encryption Public key with APKAM Symmetric key.
    enrollVerbBuilder.encryptedAPKAMSymmetricKey =
        RSAPublicKey.fromString(defaultEncryptionPublicKey)
            .encrypt(apkamSymmetricKey.key);
    enrollVerbBuilder.otp = enrollmentRequest.otp;
    enrollVerbBuilder.namespaces = enrollmentRequest.namespaces;

    String? serverResponse =
        await _executeEnrollCommand(enrollVerbBuilder, atLookUp);
    var enrollJson = jsonDecode(serverResponse);
    var enrollmentIdFromServer = enrollJson[AtConstants.enrollmentId];
    var enrollStatus = getEnrollStatusFromString(enrollJson['status']);
    AtAuthKeys atAuthKeys = AtAuthKeys()
      ..apkamPrivateKey = apkamKeyPair.atPrivateKey.privateKey
      ..apkamPublicKey = apkamKeyPair.atPublicKey.publicKey
      ..apkamSymmetricKey = apkamSymmetricKey.key
      ..enrollmentId = enrollJson[AtConstants.enrollmentId]
      ..defaultEncryptionPublicKey = defaultEncryptionPublicKey;

    return AtEnrollmentResponse(enrollmentIdFromServer, enrollStatus)
      ..atAuthKeys = atAuthKeys;
  }

  @override
  Future<AtEnrollmentResponse> approve(
      EnrollmentRequestDecision enrollmentRequestDecision,
      AtLookUp atLookUp) async {
    if (atLookUp.atChops == null) {
      throw AtAuthenticationException(
          'The authentication keys are not initialized');
    }
    // Fetch the encryptionPrivateKey from atChops instance.
    RSAPrivateKey defaultEncryptionPrivateKey = RSAPrivateKey.fromString(
        atLookUp
            .atChops!.atChopsKeys.atEncryptionKeyPair!.atPrivateKey.privateKey);

    // Decrypt the encrypted APKAM Symmetric key to get the original APKAM symmetric key
    String apkamSymmetricKey = defaultEncryptionPrivateKey
        .decrypt(enrollmentRequestDecision.encryptedAPKAMSymmetricKey);

    // Set the APKAM Symmetric key to the AtChops Instance.
    atLookUp.atChops?.atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);

    // Fetch the encryptionPrivateKey from the atChops and encrypt with APKAM Symmetric key.
    String encryptedDefaultEncryptionPrivateKey = atLookUp.atChops
        ?.encryptString(
            atLookUp.atChops!.atChopsKeys.atEncryptionKeyPair!.atPrivateKey
                .privateKey,
            EncryptionKeyType.aes256,
            keyName: 'apkamSymmetricKey',
            iv: AtChopsUtil.generateIVLegacy())
        .result;

    // Fetch the selfEncryptionKey from the atChops and encrypt with APKAM Symmetric key.
    String encryptedDefaultSelfEncryptionKey = atLookUp.atChops
        ?.encryptString(atLookUp.atChops!.atChopsKeys.selfEncryptionKey!.key,
            EncryptionKeyType.aes256,
            keyName: 'apkamSymmetricKey', iv: AtChopsUtil.generateIVLegacy())
        .result;

    String command = 'enroll:approve:${jsonEncode({
          'enrollmentId': enrollmentRequestDecision.enrollmentId,
          'encryptedDefaultEncryptionPrivateKey':
              encryptedDefaultEncryptionPrivateKey,
          'encryptedDefaultSelfEncryptionKey': encryptedDefaultSelfEncryptionKey
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

  @override
  Future<AtEnrollmentResponse> deny(
      EnrollmentRequestDecision enrollmentRequestDecision,
      AtLookUp atLookUp) async {
    EnrollVerbBuilder denyEnrollmentBuilder = EnrollVerbBuilder()
      ..enrollmentId = enrollmentRequestDecision.enrollmentId
      ..operation = enrollmentRequestDecision.enrollOperationEnum;

    String? enrollResponse = await atLookUp
        .executeCommand(denyEnrollmentBuilder.buildCommand(), auth: true);

    enrollResponse = enrollResponse?.replaceAll('data:', '');
    var enrollmentJsonMap = jsonDecode(enrollResponse!);
    AtEnrollmentResponse enrollmentResponse = AtEnrollmentResponse(
        enrollmentJsonMap['enrollmentId'], _convertEnrollmentStatusToEnum(enrollmentJsonMap['status']));
    return enrollmentResponse;
  }

  Future<String> _getDefaultEncryptionPublicKey(AtLookUp atLookupImpl) async {
    var lookupVerbBuilder = LookupVerbBuilder()
      ..atKey = (AtKey()
        ..key = 'publickey'
        ..sharedBy = _atSign);
    String? lookupResult = await atLookupImpl.executeVerb(lookupVerbBuilder);
    if (lookupResult == null || lookupResult.isEmpty) {
      throw AtEnrollmentException(
          'Unable to lookup encryption public key. Server response is null/empty');
    }
    var defaultEncryptionPublicKey = lookupResult.replaceFirst('data:', '');
    return defaultEncryptionPublicKey;
  }

  EnrollmentStatus _convertEnrollmentStatusToEnum(String enrollmentStatus) {
    switch (enrollmentStatus) {
      case 'approved':
        return EnrollmentStatus.approved;
      case 'denied':
        return EnrollmentStatus.denied;
      case 'expired':
        return EnrollmentStatus.expired;
      case 'revoked':
        return EnrollmentStatus.revoked;
      case 'pending':
        return EnrollmentStatus.pending;
      default:
        throw AtEnrollmentException(
            '$enrollmentStatus is not a valid enrollment status');
    }
  }

  /// Creates a verb builder instance based on the [request] type
  @visibleForTesting
  @Deprecated('This method is obsolate')
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

  @override
  @Deprecated('Use submit method')
  Future<AtEnrollmentResponse> submitEnrollment(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) async {
    switch (atEnrollmentRequest) {
      case AtInitialEnrollmentRequest _:
        return await _initialClientEnrollment(atEnrollmentRequest, atLookUp);
      case AtNewEnrollmentRequest _:
        return await _newClientEnrollment(atEnrollmentRequest, atLookUp);
      default:
        throw AtEnrollmentException(
            'Invalid AtEnrollmentRequest type: ${atEnrollmentRequest.runtimeType}');
    }
  }

  @Deprecated('use submit method')
  Future<AtEnrollmentResponse> _initialClientEnrollment(
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

  @Deprecated('Use submit method')
  Future<AtEnrollmentResponse> _newClientEnrollment(
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

  @override
  Future<AtEnrollmentResponse> manageEnrollmentApproval(
      AtEnrollmentRequest atEnrollmentRequest, AtLookUp atLookUp) async {
    switch (atEnrollmentRequest.enrollOperationEnum) {
      case EnrollOperationEnum.approve:
        if (atEnrollmentRequest is! AtEnrollmentNotificationRequest) {
          throw AtEnrollmentException(
              'Invalid atEnrollmentRequest type: $atEnrollmentRequest. Please pass AtEnrollmentNotificationRequest');
        }
        EnrollmentRequestDecision enrollmentRequestDecision =
            EnrollmentRequestDecision.approved(ApprovedRequestDecisionBuilder(
                enrollmentId: atEnrollmentRequest.enrollmentId!,
                encryptedAPKAMSymmetricKey:
                    atEnrollmentRequest.encryptedApkamSymmetricKey));
        return approve(enrollmentRequestDecision, atLookUp);
      case EnrollOperationEnum.deny:
        return deny(
            EnrollmentRequestDecision.denied(atEnrollmentRequest.enrollmentId!),
            atLookUp);
      default:
        throw AtEnrollmentException('Enrollment operation is not provided');
    }
  }
}
