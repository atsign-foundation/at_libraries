import 'dart:convert';
import 'package:at_commons/src/verb/enroll_params.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests related to enroll verb', () {
    test('A test to verify enroll request params', () {
      String command =
          'enroll:request:{"enrollmentId":"1234","appName":"wavi","deviceName":"pixel","namespaces":{"wavi":"rw","__manage":"r"},"encryptedDefaultEncryptedPrivateKey":"dummy_encrypted_private_key","encryptedDefaultSelfEncryptionKey":"dummy_self_encryption_key","encryptedAPKAMSymmetricKey":"dummy_pkam_sym_key","apkamPublicKey":"abcd1234"}';
      command = command.replaceAll('enroll:request:', '');
      var enrollParams = jsonDecode(command);
      expect(enrollParams['enrollmentId'], '1234');
      expect(enrollParams['appName'], 'wavi');
      expect(enrollParams['deviceName'], 'pixel');
      expect(enrollParams['namespaces']['wavi'], 'rw');
      expect(enrollParams['namespaces']['__manage'], 'r');
      expect(enrollParams['encryptedDefaultEncryptedPrivateKey'],
          'dummy_encrypted_private_key');
      expect(enrollParams['encryptedDefaultSelfEncryptionKey'],
          'dummy_self_encryption_key');
      expect(enrollParams['encryptedAPKAMSymmetricKey'], 'dummy_pkam_sym_key');
      expect(enrollParams['apkamPublicKey'], 'abcd1234');
    });

    test('A test to verify enroll approve params', () {
      String command =
          'enroll:approve:{"enrollmentId":"123","appName":"wavi","deviceName":"pixel","namespaces":{"wavi":"rw"},"encryptedDefaultEncryptedPrivateKey":"dummy_encrypted_private_key","encryptedDefaultSelfEncryptionKey":"dummy_self_encryption_key","encryptedAPKAMSymmetricKey":"dummy_pkam_sym_key","apkamPublicKey":"abcd1234"}';
      command = command.replaceAll('enroll:approve:', '');
      var enrollParams = jsonDecode(command);
      expect(enrollParams['enrollmentId'], '123');
      expect(enrollParams['appName'], 'wavi');
      expect(enrollParams['deviceName'], 'pixel');
      expect(enrollParams['namespaces']['wavi'], 'rw');
      expect(enrollParams['encryptedDefaultEncryptedPrivateKey'],
          'dummy_encrypted_private_key');
      expect(enrollParams['encryptedDefaultSelfEncryptionKey'],
          'dummy_self_encryption_key');
      expect(enrollParams['encryptedAPKAMSymmetricKey'], 'dummy_pkam_sym_key');
      expect(enrollParams['apkamPublicKey'], 'abcd1234');
    });

    test('A test to verify enroll deny params', () {
      String command = 'enroll:deny:{"enrollmentId":"123"}';
      command = command.replaceAll('enroll:deny:', '');
      var enrollParams = jsonDecode(command);
      expect(enrollParams['enrollmentId'], '123');
    });

    test('A test to verify enroll revoke params', () {
      String command = 'enroll:revoke:{"enrollmentId":"123"}';
      command = command.replaceAll('enroll:revoke:', '');
      var enrollParams = jsonDecode(command);
      expect(enrollParams['enrollmentId'], '123');
    });
  });

  group('A group of tests to verify toJson and fromJson in EnrollParams', () {
    test('A test to verify toJson', () {
      EnrollParams enrollParams = EnrollParams()
        ..appName = 'wavi'
        ..deviceName = 'pixel'
        ..namespaces = {'wavi': 'rw', '__manage': 'r'}
        ..apkamPublicKey = 'abcd1234'
        ..enrollmentId = '1234'
        ..encryptedAPKAMSymmetricKey = 'dummy_pkam_sym_key'
        ..encryptedDefaultEncryptedPrivateKey = 'dummy_encrypted_private_key'
        ..encryptedDefaultSelfEncryptionKey = 'dummy_self_encryption_key';

      Map<String, dynamic> enrollParamsMap = enrollParams.toJson();
      expect(enrollParamsMap['appName'], 'wavi');
      expect(enrollParamsMap['deviceName'], 'pixel');
      expect(enrollParamsMap['namespaces'], {'wavi': 'rw', '__manage': 'r'});
      expect(enrollParamsMap['apkamPublicKey'], 'abcd1234');
      expect(enrollParamsMap['enrollmentId'], '1234');
      expect(
          enrollParamsMap['encryptedAPKAMSymmetricKey'], 'dummy_pkam_sym_key');
      expect(enrollParamsMap['encryptedDefaultEncryptedPrivateKey'],
          'dummy_encrypted_private_key');
      expect(enrollParamsMap['encryptedDefaultSelfEncryptionKey'],
          'dummy_self_encryption_key');
    });

    test('A test to verify fromJson', () {
      var enrollParamsMap = <String, dynamic>{};
      enrollParamsMap['appName'] = 'wavi';
      enrollParamsMap['deviceName'] = 'pixel';
      enrollParamsMap['namespaces'] = {'wavi': 'rw', '__manage': 'r'};
      enrollParamsMap['apkamPublicKey'] = 'abcd1234';
      enrollParamsMap['enrollmentId'] = '1234';
      enrollParamsMap['encryptedAPKAMSymmetricKey'] = 'dummy_pkam_sym_key';
      enrollParamsMap['encryptedDefaultEncryptedPrivateKey'] =
          'dummy_encrypted_private_key';
      enrollParamsMap['encryptedDefaultSelfEncryptionKey'] =
          'dummy_self_encryption_key';
      enrollParamsMap['otp'] = '123';

      var enrollParams = EnrollParams.fromJson(enrollParamsMap);
      expect(enrollParams.appName, 'wavi');
      expect(enrollParams.deviceName, 'pixel');
      expect(enrollParams.apkamPublicKey, 'abcd1234');
      expect(enrollParams.enrollmentId, '1234');
      expect(enrollParams.encryptedAPKAMSymmetricKey, 'dummy_pkam_sym_key');
      expect(enrollParams.encryptedDefaultEncryptedPrivateKey,
          'dummy_encrypted_private_key');
      expect(enrollParams.encryptedDefaultSelfEncryptionKey,
          'dummy_self_encryption_key');
      expect(enrollParams.otp, '123');
      expect(enrollParams.namespaces, {'wavi': 'rw', '__manage': 'r'});
    });
  });
}
