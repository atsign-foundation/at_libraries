import 'dart:collection';
import 'dart:convert';

import 'package:at_commons/at_commons.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests to verify notify verb regex', () {
    test('Test to verify notify verb with encryptedSharedKey and checksum', () {
      var command =
          'notify:update:priority:low:strategy:all:latestN:1:sharedKeyEnc:GxIjM8e/nsga3:pubKeyCS:5d52f6f2868:@bob:phone.wavi@alice:989745456';
      var verbParams = getVerbParams(VerbSyntax.notify, command);
      expect(verbParams[OPERATION], 'update');
      expect(verbParams[SHARED_KEY_ENCRYPTED], 'GxIjM8e/nsga3');
      expect(verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '5d52f6f2868');
      expect(verbParams[PRIORITY], 'low');
      expect(verbParams[LATEST_N], '1');
      expect(verbParams[VALUE], '989745456');
      expect(verbParams[STRATEGY], 'all');
    });

    test('Test to verify notify verb with delete operation', () {
      var command =
          'notify:delete:priority:low:strategy:all:latestN:1:sharedKeyEnc:GxIjM8e/nsga3:pubKeyCS:5d52f6f2868:@bob:phone.wavi@alice:989745456';
      var verbParams = getVerbParams(VerbSyntax.notify, command);
      expect(verbParams[OPERATION], 'delete');
      expect(verbParams[SHARED_KEY_ENCRYPTED], 'GxIjM8e/nsga3');
      expect(verbParams[SHARED_WITH_PUBLIC_KEY_CHECK_SUM], '5d52f6f2868');
      expect(verbParams[PRIORITY], 'low');
      expect(verbParams[LATEST_N], '1');
      expect(verbParams[VALUE], '989745456');
      expect(verbParams[STRATEGY], 'all');
    });
  });

  group('A group of tests to verify notify delete verb', () {
    test('Valid id sent to notify delete', () {
      var command = 'notify:remove:abcd-1234';
      var verbParams = getVerbParams(VerbSyntax.notifyRemove, command);
      expect(verbParams[ID], 'abcd-1234');
    });

    test('id not sent to notify delete', () {
      var command = 'notify:remove:';
      expect(
          () => getVerbParams(VerbSyntax.notifyRemove, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == 'command does not match the regex')));
    });
  });
  group('A group of tests to verify pkam verb regex', () {
    test('pkam regex without signing algo', () {
      var command = 'pkam:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with rsa2048 signing algo and sha256 hashing algo', () {
      var command = 'pkam:signingAlgo:rsa2048:hashingAlgo:sha256:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], 'rsa2048');
      expect(verbParams[AT_PKAM_HASHING_ALGO], 'sha256');
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with ecc signing algo and sha256 hashing algo', () {
      var command =
          'pkam:signingAlgo:ecc_secp256r1:hashingAlgo:sha256:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], 'ecc_secp256r1');
      expect(verbParams[AT_PKAM_HASHING_ALGO], 'sha256');
      expect(verbParams[AT_PKAM_SIGNATURE], 'abcd1234');
    });
    test('pkam regex with invalid signing algo', () {
      var command = 'pkam:signingAlgo:ecc:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_SIGNING_ALGO], isNull);
    });
    test('pkam regex with invalid hashing algo', () {
      var command = 'pkam:hashingAlgo:md5:abcd1234';
      var verbParams = getVerbParams(VerbSyntax.pkam, command);
      expect(verbParams[AT_PKAM_HASHING_ALGO], isNull);
    });
  });
  group('A group of positive tests to verify keys verb regex', () {
    test('keys verb  - put public key', () {
      var command =
          'keys:put:public:namespace:__global:keyType:rsa2048:keyName:encryption_123-a abcd1234';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[keyType], 'rsa2048');
      expect(verbParams[visibility], 'public');
      expect(verbParams[keyValue], 'abcd1234');
      expect(verbParams[namespace], '__global');
      expect(verbParams[AT_OPERATION], 'put');
      expect(verbParams[keyName], 'encryption_123-a');
    });

    test('keys verb - put private key', () {
      var command =
          'keys:put:private:namespace:__private:keyType:aes:keyName:secretKey abcd1234';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[keyType], 'aes');
      expect(verbParams[visibility], 'private');
      expect(verbParams[keyValue], 'abcd1234');
      expect(verbParams[namespace], '__private');
      expect(verbParams[AT_OPERATION], 'put');
      expect(verbParams[keyName], 'secretKey');
    });

    test('keys verb - put private key with app and device name', () {
      var command =
          'keys:put:private:namespace:__private:appName:wavi:deviceName:pixel:keyType:aes:keyName:secretKey abcd1234';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[keyType], 'aes');
      expect(verbParams[visibility], 'private');
      expect(verbParams[keyValue], 'abcd1234');
      expect(verbParams[namespace], '__private');
      expect(verbParams[AT_OPERATION], 'put');
      expect(verbParams[keyName], 'secretKey');
      expect(verbParams[APP_NAME], 'wavi');
      expect(verbParams[deviceName], 'pixel');
    });

    test('keys verb - put self key with encryption key name', () {
      var command =
          'keys:put:self:namespace:__global:keyType:aes256:encryptionKeyName:encryption_123-a:keyName:mykey zcsfsdff';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[keyType], 'aes256');
      expect(verbParams[visibility], 'self');
      expect(verbParams[keyValue], 'zcsfsdff');
      expect(verbParams[namespace], '__global');
      expect(verbParams[AT_OPERATION], 'put');
      expect(verbParams[keyName], 'mykey');
      expect(verbParams[encryptionKeyName], 'encryption_123-a');
    });

    test('keys verb - get private keys', () {
      var command = 'keys:get:private';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[visibility], 'private');
    });

    test('keys verb - get self keys', () {
      var command = 'keys:get:self';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[visibility], 'self');
    });

    test('keys verb - get public keys', () {
      var command = 'keys:get:public';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[visibility], 'public');
    });

    test('keys verb - get key by name', () {
      var command = 'keys:get:keyName:firstKey';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[AT_OPERATION], 'get');
      expect(verbParams[keyName], 'firstKey');
    });

    test('keys verb - get key by name with emoji', () {
      var command = 'keys:get:keyName:firstKey🛠';
      var verbParams = getVerbParams(VerbSyntax.keys, command);
      expect(verbParams[AT_OPERATION], 'get');
      expect(verbParams[keyName], 'firstKey🛠');
    });
  });

  group('A group of negative tests to keys verb regex', () {
    test('keys verb  - invalid operation', () {
      var command = 'keys:fetch:keyName:abc123';
      expect(
          () => getVerbParams(VerbSyntax.keys, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == 'command does not match the regex')));
    });
  });

  group('A group of positive tests to verify monitor verb regex', () {
    test('monitor verb syntax - no additional params', () {
      var command = 'monitor';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[MONITOR_STRICT_MODE], null);
      expect(verbParams[MONITOR_MULTIPLEXED_MODE], null);
      expect(verbParams[MONITOR_REGEX], null);
      expect(verbParams[EPOCH_MILLIS], null);
    });
    test('monitor verb syntax - strict mode', () {
      var command = 'monitor:strict';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[MONITOR_STRICT_MODE], 'strict');
    });
    test('monitor verb syntax - multiplexed mode', () {
      var command = 'monitor:multiplexed';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[MONITOR_MULTIPLEXED_MODE], 'multiplexed');
    });
    test('monitor verb syntax - with last notification time', () {
      var command = 'monitor:1234';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[EPOCH_MILLIS], '1234');
    });
    test('monitor verb syntax - with regex', () {
      var command = 'monitor .wavi';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[MONITOR_REGEX], '.wavi');
    });
    test('monitor verb syntax - self notification enabled', () {
      var command = 'monitor:selfNotifications';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      print(verbParams);
      expect(verbParams[MONITOR_SELF_NOTIFICATIONS], 'selfNotifications');
    });

    test('monitor verb syntax - multiple params', () {
      var command = 'monitor:strict:selfNotifications:multiplexed .wavi';
      var verbParams = getVerbParams(VerbSyntax.monitor, command);
      expect(verbParams[MONITOR_STRICT_MODE], 'strict');
      expect(verbParams[MONITOR_MULTIPLEXED_MODE], 'multiplexed');
      expect(verbParams[MONITOR_SELF_NOTIFICATIONS], 'selfNotifications');
      expect(verbParams[MONITOR_REGEX], '.wavi');
    });
  });

  group('A group of tests related to enroll verb', () {
    test('A test to verify enroll request params', () {
      String command =
          'enroll:request:{"enrollmentId":"1234","appName":"wavi","deviceName":"pixel","namespaces":{"wavi":"rw","__manage":"r"},"encryptedDefaultEncryptedPrivateKey":"dummy_encrypted_private_key","encryptedDefaultSelfEncryptionKey":"dummy_self_encryption_key","encryptedAPKAMSymmetricKey":"dummy_pkam_sym_key","apkamPublicKey":"abcd1234"}\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(enrollVerbParams['operation'], 'request');
      var verbParams = jsonDecode(enrollVerbParams['enrollParams']!);
      expect(verbParams['enrollmentId'], '1234');
      expect(verbParams['appName'], 'wavi');
      expect(verbParams['deviceName'], 'pixel');
      expect(verbParams['namespaces']['wavi'], 'rw');
      expect(verbParams['namespaces']['__manage'], 'r');
      expect(verbParams['encryptedDefaultEncryptedPrivateKey'],
          'dummy_encrypted_private_key');
      expect(verbParams['encryptedDefaultSelfEncryptionKey'],
          'dummy_self_encryption_key');
      expect(verbParams['encryptedAPKAMSymmetricKey'], 'dummy_pkam_sym_key');
      expect(verbParams['apkamPublicKey'], 'abcd1234');
    });

    test('A test to verify enroll approve params', () {
      String command =
          'enroll:approve:{"enrollmentId":"1234","appName":"wavi","deviceName":"pixel","namespaces":{"wavi":"rw","__manage":"r"},"encryptedDefaultEncryptedPrivateKey":"dummy_encrypted_private_key","encryptedDefaultSelfEncryptionKey":"dummy_self_encryption_key","encryptedAPKAMSymmetricKey":"dummy_pkam_sym_key","apkamPublicKey":"abcd1234"}\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(enrollVerbParams['operation'], 'approve');
      var verbParams = jsonDecode(enrollVerbParams['enrollParams']!);
      expect(verbParams['enrollmentId'], '1234');
      expect(verbParams['appName'], 'wavi');
      expect(verbParams['deviceName'], 'pixel');
      expect(verbParams['namespaces']['wavi'], 'rw');
      expect(verbParams['namespaces']['__manage'], 'r');
      expect(verbParams['encryptedDefaultEncryptedPrivateKey'],
          'dummy_encrypted_private_key');
      expect(verbParams['encryptedDefaultSelfEncryptionKey'],
          'dummy_self_encryption_key');
      expect(verbParams['encryptedAPKAMSymmetricKey'], 'dummy_pkam_sym_key');
      expect(verbParams['apkamPublicKey'], 'abcd1234');
    });

    test('A test to verify enroll deny params', () {
      String command = 'enroll:deny:{"enrollmentId":"1234"}\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(enrollVerbParams['operation'], 'deny');
      var verbParams = jsonDecode(enrollVerbParams['enrollParams']!);
      expect(verbParams['enrollmentId'], '1234');
    });

    test('A test to verify enroll revoke params', () {
      String command = 'enroll:revoke:{"enrollmentId":"1234"}\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(enrollVerbParams['operation'], 'revoke');
      var verbParams = jsonDecode(enrollVerbParams['enrollParams']!);
      expect(verbParams['enrollmentId'], '1234');
    });

    test('A test to assert enroll list command', () {
      String command = 'enroll:list\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.enroll, command.trim())!;
      expect(enrollVerbParams['operation'], 'list');
    });

    test('A test to verify enroll list throws exception if appended with :',
        () {
      String command = 'enroll:list:\n';
      expect(
          () => getVerbParams(VerbSyntax.enroll, command),
          throwsA(predicate((dynamic e) =>
              e is InvalidSyntaxException &&
              e.message == 'command does not match the regex')));
    });
  });

  group('A group of tests related to otp verb', () {
    test('A test to verify otp verb for get operation', () {
      String command = 'otp:get\n';
      var enrollVerbParams =
          VerbUtil.getVerbParam(VerbSyntax.otp, command.trim())!;
      expect(enrollVerbParams['operation'], 'get');
    });
  });
}

Map getVerbParams(String regex, String command) {
  var regExp = RegExp(regex, caseSensitive: false);
  if (!regExp.hasMatch(command)) {
    throw InvalidSyntaxException('command does not match the regex');
  }
  var regexMatches = regExp.allMatches(command);
  var paramsMap = HashMap<String, String?>();
  for (var f in regexMatches) {
    for (var name in f.groupNames) {
      paramsMap.putIfAbsent(name, () => f.namedGroup(name));
    }
  }
  return paramsMap;
}
