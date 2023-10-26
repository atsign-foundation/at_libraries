import 'dart:convert';

import 'package:at_auth/at_auth.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_client/at_client.dart';
import 'dart:io';
import 'package:at_auth/src/auth_constants.dart' as auth_constants;

import 'atsign_preference.dart';

/// dart enroll_app_listen.dart <atsign> <path_to_key_file>
void main(List<String> arguments) async {
  var aliceAtSign = arguments[0];
  try {
    var atAuthKeys = _decryptAtKeysFile(await _readAtKeysFile(arguments[1]));
    var atChops = _createAtChops(atAuthKeys);
    final atClientManager = await AtClientManager.getInstance()
        .setCurrentAtSign(
            aliceAtSign,
            'wavi',
            AtSignPreference.getAlicePreference(
                aliceAtSign, atAuthKeys.enrollmentId!),
            atChops: atChops,
            enrollmentId: atAuthKeys.enrollmentId);

    // alice - listen for notification
    atClientManager.atClient.notificationService
        .subscribe(regex: '.__manage')
        .listen((notification) {
      _notificationCallback(notification, atClientManager.atClient, atAuthKeys);
    });
  } on Exception catch (e, trace) {
    print(e.toString());
    print(trace);
  }

  print('end of test');
}

Future<void> _notificationCallback(AtNotification notification,
    AtClient atClient, AtAuthKeys atAuthKeys) async {
  print('alice enroll notification received: ${notification.toString()}');
  final notificationKey = notification.key;
  final enrollmentId =
      notificationKey.substring(0, notificationKey.indexOf('.new.enrollments'));
  print('Approve enrollmentId $enrollmentId?');
  String? approveResponse = stdin.readLineSync();
  print('approved?: $approveResponse');
  var enrollRequest;
  var enrollParamsJson = {};
  enrollParamsJson['enrollmentId'] = enrollmentId;
  if (approveResponse == 'yes') {
    final encryptedApkamSymmetricKey =
        jsonDecode(notification.value!)['encryptedApkamSymmetricKey'];
    final apkamSymmetricKey = EncryptionUtil.decryptKey(
        encryptedApkamSymmetricKey, atAuthKeys.defaultEncryptionPrivateKey!);
    print('decrypted apkam symmetric key: $apkamSymmetricKey');
    var encryptedDefaultPrivateEncKey = EncryptionUtil.encryptValue(
        atAuthKeys.defaultEncryptionPrivateKey!, apkamSymmetricKey);
    var encryptedDefaultSelfEncKey = EncryptionUtil.encryptValue(
        atAuthKeys.defaultSelfEncryptionKey!, apkamSymmetricKey);
    enrollParamsJson['encryptedDefaultEncryptedPrivateKey'] =
        encryptedDefaultPrivateEncKey;
    enrollParamsJson['encryptedDefaultSelfEncryptionKey'] =
        encryptedDefaultSelfEncKey;
    enrollRequest = 'enroll:approve:${jsonEncode(enrollParamsJson)}\n';
  } else {
    enrollRequest = 'enroll:deny:${jsonEncode(enrollParamsJson)}\n';
  }
  print('enroll request to server: $enrollRequest');
  String? enrollResponse = await atClient
      .getRemoteSecondary()!
      .executeCommand(enrollRequest, auth: true);
  print('enrollResponse: $enrollResponse');
}

AtAuthKeys _decryptAtKeysFile(Map<String, String> jsonData) {
  var securityKeys = AtAuthKeys();
  String decryptionKey = jsonData[auth_constants.defaultSelfEncryptionKey]!;
  var atChops =
      AtChopsImpl(AtChopsKeys()..selfEncryptionKey = AESKey(decryptionKey));
  securityKeys.defaultEncryptionPublicKey = atChops
      .decryptString(jsonData[auth_constants.defaultEncryptionPublicKey]!,
          EncryptionKeyType.aes256,
          keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
      .result;
  securityKeys.defaultEncryptionPrivateKey = atChops
      .decryptString(jsonData[auth_constants.defaultEncryptionPrivateKey]!,
          EncryptionKeyType.aes256,
          keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
      .result;
  securityKeys.defaultSelfEncryptionKey = decryptionKey;
  securityKeys.apkamPublicKey = atChops
      .decryptString(
          jsonData[auth_constants.apkamPublicKey]!, EncryptionKeyType.aes256,
          keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
      .result;
  securityKeys.apkamPrivateKey = atChops
      .decryptString(
          jsonData[auth_constants.apkamPrivateKey]!, EncryptionKeyType.aes256,
          keyName: 'selfEncryptionKey', iv: AtChopsUtil.generateIVLegacy())
      .result;
  securityKeys.apkamSymmetricKey = jsonData[auth_constants.apkamSymmetricKey];
  securityKeys.enrollmentId = jsonData[AtConstants.enrollmentId];
  return securityKeys;
}

Future<Map<String, String>> _readAtKeysFile(String? atKeysFilePath) async {
  if (atKeysFilePath == null || atKeysFilePath.isEmpty) {
    throw AtException(
        'atKeys filePath is empty. atKeysFile is required to authenticate');
  }
  if (!File(atKeysFilePath).existsSync()) {
    throw AtException(
        'provided keys file does not exist. Please check whether the file path $atKeysFilePath is valid');
  }
  String atAuthData = await File(atKeysFilePath).readAsString();
  Map<String, String> jsonData = <String, String>{};
  json.decode(atAuthData).forEach((String key, dynamic value) {
    jsonData[key] = value.toString();
  });
  return jsonData;
}

AtChops _createAtChops(AtAuthKeys atKeysFile) {
  final atEncryptionKeyPair = AtEncryptionKeyPair.create(
      atKeysFile.defaultEncryptionPublicKey!,
      atKeysFile.defaultEncryptionPrivateKey!);
  final atPkamKeyPair = AtPkamKeyPair.create(
      atKeysFile.apkamPublicKey!, atKeysFile.apkamPrivateKey!);
  final atChopsKeys = AtChopsKeys.create(atEncryptionKeyPair, atPkamKeyPair);
  if (atKeysFile.apkamSymmetricKey != null) {
    atChopsKeys.apkamSymmetricKey = AESKey(atKeysFile.apkamSymmetricKey!);
  }
  atChopsKeys.selfEncryptionKey = AESKey(atKeysFile.defaultSelfEncryptionKey!);
  return AtChopsImpl(atChopsKeys);
}
