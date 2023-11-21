import 'dart:convert';
import 'dart:io';

import 'package:at_auth/at_auth.dart';
import 'package:at_lookup/at_lookup.dart';
import 'package:at_chops/at_chops.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_commons/at_builders.dart';
import 'package:crypton/crypton.dart';

class AtEnrollmentService {
  String rootDomain = 'root.atsign.org';
  int rootPort = 64;
  AtAuthImpl atAuthImpl = AtAuthImpl();

  String atSign;
  late AtLookUp atLookUp;
  late AtAuthRequest atAuthRequest;

  AtEnrollmentService(this.atSign) {
    atLookUp = AtLookupImpl(atSign, rootDomain, rootPort);
    atAuthRequest = AtAuthRequest(atSign);
  }

  Future<void> authenticate(String atKeysFilePath) async {
    atAuthRequest.atKeysFilePath = atKeysFilePath;
    AtAuthResponse atAuthResponse =
        await atAuthImpl.authenticate(atAuthRequest);

    if (atAuthResponse.isSuccessful == false) {
      throw AtEnrollmentService('Failed to authenticate $atSign');
    }
    // Populate AtChops in atLookup.
    atLookUp.atChops = atAuthImpl.atChops;
  }

  Future<String?> fetchOTP() async {
    String? otp = await atLookUp.executeCommand('otp:get\n', auth: true);
    otp = otp?.replaceFirst('data:', '');
    stdout.writeln(
        '[Information] Use the following link to submit enrollment: atsign://submit.enrollment/submitEnrollment?otp=$otp');
    atLookUp.close();
    return otp;
  }

  Future<void> initMonitor() async {
    SecondaryAddress secondaryAddress =
        await atLookUp.secondaryAddressFinder.findSecondary(atSign);

    SecureSocketConfig secureSocketConfig = SecureSocketConfig();
    secureSocketConfig.decryptPackets = false;

    SecureSocket monitorSocket = await SecureSocketUtil.createSecureSocket(
        secondaryAddress.host,
        secondaryAddress.port.toString(),
        secureSocketConfig);

    monitorSocket.write('from:$atSign\n');

    monitorSocket.listen((data) {
      String serverResponse = utf8.decode(data);
      serverResponse = serverResponse.trim();
      // From response starts with "data:_"
      if (serverResponse.startsWith('data:_')) {
        serverResponse = serverResponse.replaceAll('data:', '');
        serverResponse =
            serverResponse.substring(0, serverResponse.indexOf('\n'));
        final atSigningInput = AtSigningInput(serverResponse)
          ..signingAlgoType = SigningAlgoType.rsa2048
          ..hashingAlgoType = HashingAlgoType.sha256
          ..signingMode = AtSigningMode.pkam;
        var signingResult = atLookUp.atChops!.sign(atSigningInput);
        var pkamBuilder = PkamVerbBuilder()
          ..signingAlgo = SigningAlgoType.rsa2048.name
          ..hashingAlgo = HashingAlgoType.sha256.name
          ..signature = signingResult.result;
        var pkamCommand = pkamBuilder.buildCommand();
        monitorSocket.write('$pkamCommand\n');
      }
      // CRAM Response starts-with "data:success"
      else if (serverResponse.startsWith('data:success')) {
        print('[Information] Connection Authenticated Successfully');
        monitorSocket.write('monitor:selfNotifications __manage\n');
      }
      // Response on monitor starts with "notification:"
      else if (serverResponse.startsWith('notification:')) {
        serverResponse = serverResponse.replaceFirst('notification:', '');
        Map notificationMap = jsonDecode(serverResponse);
        if (notificationMap['id'] != '-1') {
          _autoApproveEnrollment(notificationMap);
        }
      }
    });
  }

  _autoApproveEnrollment(Map notificationMap) async {
    String encryptedApkamSymmetricKey =
        jsonDecode(notificationMap['value'])['encryptedApkamSymmetricKey'];
    String enrollmentId = notificationMap['key']
        .substring(0, notificationMap['key'].indexOf('.'));
    stdout
        .writeln('[Information] Auto approving the enrollment : $enrollmentId');

    var defaultEncryptionPrivateKey = RSAPrivateKey.fromString(atLookUp
        .atChops!.atChopsKeys.atEncryptionKeyPair!.atPrivateKey.privateKey);
    var apkamSymmetricKey =
        defaultEncryptionPrivateKey.decrypt(encryptedApkamSymmetricKey);
    atLookUp.atChops?.atChopsKeys.apkamSymmetricKey = AESKey(apkamSymmetricKey);

    String command = 'enroll:approve:${jsonEncode({
          'enrollmentId': enrollmentId,
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
    print('[Information] $enrollResponse');
    await atLookUp.close();
  }
}
